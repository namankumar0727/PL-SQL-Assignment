/*========================================================
BANK ACCOUNT MANAGEMENT SYSTEM


1. TABLE CREATION

*/

CREATE TABLE bank_users (
    user_id      NUMBER PRIMARY KEY,
    user_name    VARCHAR2(100) NOT NULL,
    date_of_birth DATE,
    contact_no   VARCHAR2(25),
    email_addr   VARCHAR2(100),
    join_date    DATE DEFAULT SYSDATE
);

CREATE TABLE user_accounts (
    acc_id     NUMBER PRIMARY KEY,
    user_id    NUMBER NOT NULL,
    acc_type   VARCHAR2(20),
    curr_bal   NUMBER(12,2) DEFAULT 0,
    acc_state  VARCHAR2(12) DEFAULT 'ACTIVE',
    CONSTRAINT fk_user
    FOREIGN KEY (user_id)
    REFERENCES bank_users(user_id)
);

CREATE TABLE txn_records (
    txn_id    NUMBER PRIMARY KEY,
    acc_id    NUMBER,
    txn_kind  VARCHAR2(10),
    txn_amt   NUMBER(12,2),
    txn_date  DATE DEFAULT SYSDATE,
    CONSTRAINT fk_acc
    FOREIGN KEY (acc_id)
    REFERENCES user_accounts(acc_id)
);


/*
2. SEQUENCES
*/

CREATE SEQUENCE user_seq START WITH 701 INCREMENT BY 1;
CREATE SEQUENCE accno_seq START WITH 4501 INCREMENT BY 1;
CREATE SEQUENCE txnno_seq START WITH 70001 INCREMENT BY 1;


/*
3. PROCEDURE : REGISTER USER
   AND OPEN ACCOUNT
*/

CREATE OR REPLACE PROCEDURE register_user_account (
    p_name     IN VARCHAR2,
    p_dob      IN DATE,
    p_contact  IN VARCHAR2,
    p_email    IN VARCHAR2,
    p_acc_type IN VARCHAR2
)
IS
    v_user_id NUMBER;
    v_acc_id  NUMBER;
BEGIN
    v_user_id := user_seq.NEXTVAL;

    INSERT INTO bank_users
    VALUES (
        v_user_id,
        p_name,
        p_dob,
        p_contact,
        p_email,
        SYSDATE
    );

    v_acc_id := accno_seq.NEXTVAL;

    INSERT INTO user_accounts
    VALUES (
        v_acc_id,
        v_user_id,
        p_acc_type,
        0,
        'ACTIVE'
    );

    COMMIT;
END;
/
    

/*
4. PROCEDURE : ADD FUNDS
*/

CREATE OR REPLACE PROCEDURE add_funds (
    p_acc_id IN NUMBER,
    p_amount IN NUMBER
)
BEGIN
    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20201, 'Invalid deposit amount');
    END IF;

    UPDATE user_accounts
    SET curr_bal = curr_bal + p_amount
    WHERE acc_id = p_acc_id;

    INSERT INTO txn_records
    VALUES (
        txnno_seq.NEXTVAL,
        p_acc_id,
        'CREDIT',
        p_amount,
        SYSDATE
    );

    COMMIT;
END;
/
    

/*
5. PROCEDURE : REMOVE FUNDS
*/

CREATE OR REPLACE PROCEDURE remove_funds (
    p_acc_id IN NUMBER,
    p_amount IN NUMBER
)
IS
    v_bal NUMBER;
BEGIN
    SELECT curr_bal
    INTO v_bal
    FROM user_accounts
    WHERE acc_id = p_acc_id;

    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20202, 'Invalid withdrawal amount');
    END IF;

    IF v_bal < p_amount THEN
        RAISE_APPLICATION_ERROR(-20203, 'Not enough balance');
    END IF;

    UPDATE user_accounts
    SET curr_bal = curr_bal - p_amount
    WHERE acc_id = p_acc_id;

    INSERT INTO txn_records
    VALUES (
        txnno_seq.NEXTVAL,
        p_acc_id,
        'DEBIT',
        p_amount,
        SYSDATE
    );

    COMMIT;
END;
/
    

/*
6. FUNCTION : FETCH BALANCE
*/

CREATE OR REPLACE FUNCTION fetch_balance (
    p_acc_id IN NUMBER
)
RETURN NUMBER
IS
    v_amount NUMBER;
BEGIN
    SELECT curr_bal
    INTO v_amount
    FROM user_accounts
    WHERE acc_id = p_acc_id;

    RETURN v_amount;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END;
/
    

/*
7. TRIGGER : TRANSACTION NOTICE
*/

CREATE OR REPLACE TRIGGER trg_txn_notice
AFTER INSERT ON txn_records
FOR EACH ROW
BEGIN
    DBMS_OUTPUT.PUT_LINE(
        'Transaction ID ' || :NEW.txn_id ||
        ' processed for Account ' || :NEW.acc_id
    );
END;
/
    

/*
8.TESTING
*/

-- Register user and open account
EXEC register_user_account(
    'Naman Kumar',
    DATE '2005-07-27',
    '1233456780',
    'namankumar@gmail.com',
    'SAVINGS'
);

-- Add money
EXEC add_funds(4501, 8000);

-- Withdraw money
EXEC remove_funds(4501, 2500);

-- Check balance
SELECT fetch_balance(4501) AS balance FROM dual;

-- View transactions
SELECT * FROM txn_records WHERE acc_id = 4501;
