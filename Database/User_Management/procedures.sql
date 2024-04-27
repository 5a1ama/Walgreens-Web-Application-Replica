-- Function: register_user
/*
Description: Registers a new user with their personal details into the system.
Parameters:
- p_first_name: First name of the user (VARCHAR).
- p_last_name: Last name of the user (VARCHAR).
- p_email: Email address of the user (VARCHAR).
- p_password: Password for the user's account (VARCHAR).
Returns: Status message indicating successful registration (VARCHAR).
*/
CREATE OR REPLACE FUNCTION register_user(
    p_first_name VARCHAR,
    p_last_name VARCHAR,
    p_email VARCHAR,
    p_password VARCHAR
)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id VARCHAR;
BEGIN
    INSERT INTO "User" ("id", "email", "password", "status", "role")
    VALUES (gen_random_uuid(), p_email, p_password, 'Active','Customer')
    RETURNING "id" INTO v_user_id;

    INSERT INTO "Customer" ("id", "first_name", "last_name")
    VALUES (v_user_id, p_first_name, p_last_name);

    RETURN 'Successfully registered user';
END;
$$;

-- Function: edit_personal_details
/*
Description: Edits personal details of an existing user based on provided information.
Parameters:
- p_user_id: User ID of the user whose details are being edited (VARCHAR).
- p_address, p_date_of_birth, p_gender: New address, date of birth, and gender of the user (VARCHAR, DATE, "Gender" ENUM).
- p_phone_number, p_extension: New phone number and its extension if provided (INT, VARCHAR).
Returns: Status message indicating successful update (VARCHAR).
*/
CREATE OR REPLACE FUNCTION edit_personal_details(
    p_user_id VARCHAR,
    p_address VARCHAR DEFAULT NULL,
    p_date_of_birth DATE DEFAULT NULL,
    p_gender "Gender" DEFAULT NULL,
    p_phone_number VARCHAR DEFAULT NULL,
    p_extension VARCHAR DEFAULT NULL,
    OUT status VARCHAR ,
    OUT message VARCHAR
)
RETURNS record
LANGUAGE plpgsql
AS $$
DECLARE
    v_phone_id VARCHAR;
    v_old_phone_number VARCHAR;
    v_old_phone_extension VARCHAR;
    v_message VARCHAR := 'Details updated successfully for: ';
    v_first BOOLEAN := TRUE;
BEGIN
    IF p_address IS NULL AND p_date_of_birth IS NULL AND p_gender IS NULL AND p_phone_number IS NULL AND p_extension IS NULL THEN
        status := 'Failure';
        message := 'No details provided for update';
    END IF;

    -- Check if phone number and extension are provided together the first time
        IF v_old_phone_number IS NULL AND v_old_phone_extension IS NULL THEN
          IF p_phone_number IS NOT NULL AND p_extension IS NULL OR p_phone_number IS NULL AND p_extension IS NOT NULL THEN
                  status := 'Failure';
                  message := 'Phone number and extension must be provided together the first time';
          END IF;
        END IF;
      IF p_phone_number IS NOT NULL OR p_extension IS NOT NULL THEN
        SELECT v_phone_id = "phone_id", v_old_phone_number = "number", v_old_phone_extension = "extension"
        FROM "Customer"
        WHERE "id" = p_user_id;
          IF v_phone_id IS NOT NULL THEN
              UPDATE "Customer"
              SET "phone_id" = NULL
              WHERE "id" = p_user_id;

              DELETE FROM "Phone_Number"
              WHERE "id" = v_phone_id;
          END IF;

          -- Insert new phone number with the extension (handling possible NULLs in extension)
          INSERT INTO "Phone_Number" ("id", "number", "extension")
          VALUES (gen_random_uuid(), p_phone_number, p_extension)
          RETURNING "id" INTO v_phone_id;

          -- Update Customer with new phone_id
          UPDATE "Customer"
          SET "phone_id" = v_phone_id
          WHERE "id" = p_user_id;

          -- Append to message if phone number or extension was updated
          IF p_phone_number IS NOT NULL THEN
              IF v_first THEN
                  v_message := v_message || 'phone number';
                  v_first := FALSE;
              ELSE
                  v_message := v_message || ', phone number';
              END IF;
          END IF;

          IF p_extension IS NOT NULL THEN
              IF v_first THEN
                  v_message := v_message || 'extension';
                  v_first := FALSE;
              ELSE
                  v_message := v_message || ', extension';
              END IF;
          END IF;
      END IF;

    IF p_address IS NOT NULL THEN
        IF v_first THEN
            v_message := v_message || 'address';
            v_first := FALSE;
        ELSE
            v_message := v_message || ', address';
        END IF;
    END IF;

    IF p_date_of_birth IS NOT NULL THEN
        IF v_first THEN
            v_message := v_message || 'date of birth';
            v_first := FALSE;
        ELSE
            v_message := v_message || ', date of birth';
        END IF;
    END IF;

    IF p_gender IS NOT NULL THEN
        IF v_first THEN
            v_message := v_message || 'gender';
            v_first := FALSE;
        ELSE
            v_message := v_message || ', gender';
        END IF;
    END IF;

    IF NOT v_first THEN
        UPDATE "Customer"
        SET "address" = COALESCE(p_address, "address"),
            "date_of_birth" = COALESCE(p_date_of_birth, "date_of_birth"),
            "gender" = COALESCE(p_gender, "gender")
        WHERE "id" = p_user_id;
        status := 'Success';
        message := v_message;
    END IF;
END;
$$;


-- Function: ChangePassword
/*
Description: Changes the password of an existing user after validating the old password.
Parameters:
- p_user_id: User ID of the user whose password is being changed (VARCHAR).
- p_old_password: Current password to validate (VARCHAR).
- p_new_password: New password to set (VARCHAR).
Returns: Status message indicating the result of the operation (VARCHAR).
*/
CREATE OR REPLACE FUNCTION change_password(
    p_user_id VARCHAR,
    p_old_password VARCHAR,
    p_new_password VARCHAR,
    OUT status VARCHAR,
    OUT message VARCHAR
)
RETURNS record
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_password VARCHAR;
BEGIN
    SELECT password INTO v_current_password
    FROM "User"
    WHERE id = p_user_id;
    IF v_current_password = p_old_password THEN
        IF p_new_password IS NOT NULL THEN
            UPDATE "User"
            SET password = p_new_password
            WHERE id = p_user_id;
            status := 'Success';
            message := 'Password updated successfully.';
        ELSE
            status := 'Failure';
            message := 'New password cannot be empty.';
        END IF;
    ELSE
        status := 'Failure';
        message := 'Old Password does not match.';
    END IF;
END;
$$;

-- Function: ChangeEmail
/*
Description: Changes the email of an existing user after validating the current password.
Parameters:
- p_user_id: User ID of the user whose email is being changed (VARCHAR).
- p_password: Current password to validate (VARCHAR).
- p_new_email: New email to set (VARCHAR).
Returns: Status message indicating the result of the operation (VARCHAR).
*/
CREATE OR REPLACE FUNCTION change_email(
    p_user_id VARCHAR,
    p_password VARCHAR,
    p_new_email VARCHAR,
    OUT status VARCHAR,
    OUT message VARCHAR
)
RETURNS record
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_password VARCHAR;
BEGIN
    SELECT password INTO v_current_password
    FROM "User"
    WHERE id = p_user_id;
    IF v_current_password = p_password THEN
        IF p_new_email IS NOT NULL THEN
            UPDATE "User"
            SET email = p_new_email
            WHERE id = p_user_id;
            status := 'Success';
            message := 'Email updated successfully.';
        ELSE
            status := 'Failure';
            message := 'New Email cannot be empty.';
        END IF;
    ELSE
        status := 'Failure';
        message := 'Password does not match.';
    END IF;
END;
$$;


-- Function: update_2fa_enabled
/*
Description: Updates the two-factor authentication status for a user.
Parameters:
- _id: User ID for whom the 2FA status is being updated (VARCHAR).
- _enabled: Boolean indicating whether 2FA is enabled or not (BOOLEAN).
Returns: Status message indicating the result of the operation (VARCHAR).
*/
CREATE OR REPLACE FUNCTION update_2fa_status(p_id VARCHAR, p_enabled BOOLEAN)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE "User"
    SET "2FA_Enabled" = p_enabled
    WHERE "id" = p_id;
    RETURN '2FA status updated successfully';
END;
$$;

-- Function: add_admin
/*
Description: Adds a new administrator to the system with a unique username and password.
Parameters:
- v_username: Username for the new administrator (VARCHAR).
- v_password: Password for the new administrator's account (VARCHAR).
Returns: Status message indicating successful addition of the administrator (VARCHAR).
*/
CREATE OR REPLACE FUNCTION add_admin(
    v_username VARCHAR,
    v_password VARCHAR
)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO "Administrator" ("id", "username", "password")
    VALUES (gen_random_uuid(), v_username, v_password);
    RETURN 'Administrator added successfully';
END;
$$;

-- Function: add_pharmacist
/*
Description: Adds a new pharmacist to the system, registering them as both a user and a pharmacist.
Parameters:
- p_first_name: First name of the pharmacist (VARCHAR).
- p_last_name: Last name of the pharmacist (VARCHAR).
- p_email: Email address of the pharmacist (VARCHAR).
- p_password: Password for the pharmacist's account (VARCHAR).
Returns: Status message indicating successful addition of the pharmacist (VARCHAR).
*/
CREATE OR REPLACE FUNCTION add_pharmacist(
    p_first_name VARCHAR,
    p_last_name VARCHAR,
    p_email VARCHAR,
    p_password VARCHAR
)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
    user_id VARCHAR;
BEGIN
    INSERT INTO "User" ("id", "email", "password", "status", "role")
    VALUES (gen_random_uuid(), p_email, p_password, 'Active', 'Pharmacist')
    RETURNING "id" INTO user_id;
    INSERT INTO "Pharmacist" ("id", "first_name", "last_name")
    VALUES (user_id, p_first_name, p_last_name);
    RETURN 'Pharmacist added successfully';
END;
$$;

-- Function: ban_account
/*
Description: Bans a user's account by setting its status to 'Banned'.
Parameters:
- user_id: User ID of the account to be banned (VARCHAR).
Returns: Status message indicating successful account ban (VARCHAR).
*/
CREATE OR REPLACE FUNCTION ban_account(
    p_user_id VARCHAR
)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE "User"
    SET "status" = 'Banned'
    WHERE "id" = p_user_id;
    RETURN 'Account banned successfully';
END;
$$;


-- Function: Login

/*
Description: This function is used for user login authentication.

Parameters:
- email: Email address of the user attempting to log in (VARCHAR).
- password: Password provided by the user attempting to log in (VARCHAR).

Returns: A record containing the login status and role of the user.

Notes:
- Returns 'Wrong Email or Password' if the login credentials are incorrect.
*/
CREATE OR REPLACE FUNCTION login(
    p_email VARCHAR,
    p_password VARCHAR,
    OUT status VARCHAR,
    OUT message VARCHAR,
    OUT role VARCHAR
)
RETURNS record
LANGUAGE plpgsql
AS $$
DECLARE
    v_2fa_enabled BOOLEAN;
BEGIN
    SELECT U.status, U.role, U."2FA_Enabled"
    INTO status, role, v_2fa_enabled
    FROM "User" U
    WHERE U.email = p_email AND U.password = p_password;

    IF NOT FOUND THEN
        status := 'Failure';
        message := 'Wrong Email or Password';
    ELSE
        IF v_2fa_enabled THEN
            status := 'Pending';
            message := '2FA pending. Please complete the authentication.';
        ELSE
            status := 'Success';
            message := 'Logged in successfully';
        END IF;
    END IF;

END;
$$;


-- Function: Login_Admin
/*
Description: Authenticates an administrator login attempt by verifying username and password.
Parameters:
- username: Username of the administrator attempting to log in (VARCHAR).
- password: Password provided by the administrator attempting to log in (VARCHAR).
Returns: Status message indicating the outcome of the login attempt (VARCHAR).
*/
CREATE OR REPLACE FUNCTION login_admin(
    p_username VARCHAR,
    p_password VARCHAR,
    OUT status VARCHAR,
    OUT message VARCHAR
)
RETURNS record
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT *
    FROM "Administrator" A
    WHERE A.username = p_username AND A.password = p_password;

    IF NOT FOUND THEN
        status := 'Failure';
        message := 'Wrong Email or Password';
    ELSE
        status := 'Success';
        message := 'Logged in successfully';
    END IF;

END;
$$;


