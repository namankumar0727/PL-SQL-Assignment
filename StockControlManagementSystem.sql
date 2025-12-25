/*
INVENTORY & STOCK CONTROL MANAGEMENT SYSTEM

1. TABLE CREATION
*/

CREATE TABLE store_products (
    product_id   NUMBER PRIMARY KEY,
    product_name VARCHAR2(80),
    unit_price   NUMBER(10,2),
    available_qty NUMBER DEFAULT 0,
    created_on   DATE DEFAULT SYSDATE
);

CREATE TABLE product_suppliers (
    supplier_id   NUMBER PRIMARY KEY,
    supplier_name VARCHAR2(100),
    contact_no    VARCHAR2(20),
    city          VARCHAR2(50)
);

CREATE TABLE stock_logs (
    log_id     NUMBER PRIMARY KEY,
    product_id NUMBER,
    supplier_id NUMBER,
    movement_type VARCHAR2(10), -- IN / OUT
    quantity   NUMBER,
    log_date   DATE DEFAULT SYSDATE,
    CONSTRAINT fk_prod FOREIGN KEY (product_id)
        REFERENCES store_products(product_id),
    CONSTRAINT fk_supp FOREIGN KEY (supplier_id)
        REFERENCES product_suppliers(supplier_id)
);


/*
2. SEQUENCES
*/

CREATE SEQUENCE prod_seq START WITH 3001 INCREMENT BY 1;
CREATE SEQUENCE supp_seq START WITH 6001 INCREMENT BY 1;
CREATE SEQUENCE log_seq  START WITH 90001 INCREMENT BY 1;


/*
3. PROCEDURE : ADD PRODUCT
*/

CREATE OR REPLACE PROCEDURE add_product (
    p_name  IN VARCHAR2,
    p_price IN NUMBER
)
IS
BEGIN
    INSERT INTO store_products
    VALUES (
        prod_seq.NEXTVAL,
        p_name,
        p_price,
        0,
        SYSDATE
    );

    COMMIT;
END;
/
    

/*
4. PROCEDURE : STOCK IN
*/

CREATE OR REPLACE PROCEDURE stock_inward (
    p_product_id  IN NUMBER,
    p_supplier_id IN NUMBER,
    p_qty         IN NUMBER
)
BEGIN
    IF p_qty <= 0 THEN
        RAISE_APPLICATION_ERROR(-21001, 'Invalid stock quantity');
    END IF;

    INSERT INTO stock_logs
    VALUES (
        log_seq.NEXTVAL,
        p_product_id,
        p_supplier_id,
        'IN',
        p_qty,
        SYSDATE
    );

    COMMIT;
END;
/
    

/*
5. PROCEDURE : STOCK OUT (SALE)
*/

CREATE OR REPLACE PROCEDURE stock_outward (
    p_product_id IN NUMBER,
    p_qty        IN NUMBER
)
IS
    v_stock NUMBER;
BEGIN
    SELECT available_qty
    INTO v_stock
    FROM store_products
    WHERE product_id = p_product_id;

    IF p_qty > v_stock THEN
        RAISE_APPLICATION_ERROR(
            -21002,
            'Insufficient stock available'
        );
    END IF;

    INSERT INTO stock_logs
    VALUES (
        log_seq.NEXTVAL,
        p_product_id,
        NULL,
        'OUT',
        p_qty,
        SYSDATE
    );

    COMMIT;
END;
/
    

/*
6. TRIGGER : AUTO UPDATE STOCK
*/

CREATE OR REPLACE TRIGGER trg_stock_update
AFTER INSERT ON stock_logs
FOR EACH ROW
BEGIN
    IF :NEW.movement_type = 'IN' THEN
        UPDATE store_products
        SET available_qty = available_qty + :NEW.quantity
        WHERE product_id = :NEW.product_id;

    ELSIF :NEW.movement_type = 'OUT' THEN
        UPDATE store_products
        SET available_qty = available_qty - :NEW.quantity
        WHERE product_id = :NEW.product_id;
    END IF;
END;
/
    

/*
7. FUNCTION : CHECK STOCK
*/

CREATE OR REPLACE FUNCTION get_available_stock (
    p_product_id IN NUMBER
)
RETURN NUMBER
IS
    v_qty NUMBER;
BEGIN
    SELECT available_qty
    INTO v_qty
    FROM store_products
    WHERE product_id = p_product_id;

    RETURN v_qty;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END;
/
    

/*
8. CURSOR : LOW STOCK REPORT
*/

CREATE OR REPLACE PROCEDURE low_stock_report
IS
    CURSOR c_low IS
        SELECT product_id, product_name, available_qty
        FROM store_products
        WHERE available_qty < 10;
BEGIN
    FOR rec IN c_low LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Product: ' || rec.product_name ||
            ' | Stock Left: ' || rec.available_qty
        );
    END LOOP;
END;
/
    

/*
9.  TESTING
*/

-- Add supplier
INSERT INTO product_suppliers
VALUES (supp_seq.NEXTVAL, 'Naman Traders', '9876543210', 'Bhopal');

-- Add product
EXEC add_product('Wireless Mouse', 750);

-- Stock In
EXEC stock_inward(3001, 6001, 50);

-- Stock Out (Sale)
EXEC stock_outward(3001, 45);

-- Check stock
SELECT get_available_stock(3001) AS remaining_stock FROM dual;

-- Low stock alert
EXEC low_stock_report;

-- View stock logs
SELECT * FROM stock_logs;
