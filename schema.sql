------------------------------------
------------------------------------
--                                --
--         Clear DB               --
--                                --
------------------------------------
------------------------------------


DROP SCHEMA "public" CASCADE;
CREATE SCHEMA "public";
GRANT ALL ON SCHEMA "public" TO postgres;
GRANT ALL ON SCHEMA "public" TO public;



------------------------------------
------------------------------------
--                                --
--         Constraints            --
--                                --
------------------------------------
------------------------------------

CREATE EXTENSION pgcrypto;


CREATE FUNCTION check_cpf(cpf INT8) RETURNS boolean AS $$
DECLARE
  dv1 INT8;
  dv2 INT8;
  calc_dv1 INT8;
  calc_dv2 INT8;
  i INTEGER;  
BEGIN
  IF cpf IS NULL THEN
	  RETURN TRUE;
  END IF;

  IF (cpf >= 99999999999 OR
      cpf = 88888888888 OR
      cpf = 77777777777 OR
      cpf = 66666666666 OR
      cpf = 55555555555 OR
      cpf = 44444444444 OR
      cpf = 33333333333 OR
      cpf = 22222222222 OR
      cpf = 11111111111 OR
      cpf = 0) THEN
    RETURN false;
  END IF;
  dv2 := cpf % 10;
  cpf := cpf / 10;
  dv1 := cpf % 10;
  cpf := cpf / 10;

  i := 2;
  calc_dv1 := 0;
  calc_dv2 := dv1 * i;

  LOOP
    EXIT WHEN i >= 11;
    calc_dv1 := calc_dv1 + i * (cpf % 10);
    i := i + 1;
    calc_dv2 := calc_dv2 + i * (cpf % 10);
    cpf := cpf / 10;
  END LOOP;

  calc_dv1 := calc_dv1 % 11;
  calc_dv2 := calc_dv2 % 11;

  IF ( calc_dv1 <= 1 ) THEN
    calc_dv1 := 0;
  ELSE
    calc_dv1 := 11 - calc_dv1;
  END IF;

  IF ( calc_dv2 <= 1 ) THEN
    calc_dv2 := 0;
  ELSE
    calc_dv2 := 11 - calc_dv2;
  END IF;

  RETURN ( dv1 = calc_dv1 AND dv2 = calc_dv2);
END;
$$ LANGUAGE plpgsql;

------------------------------------
------------------------------------
--                                --
--         Tables                 --
--                                --
------------------------------------
------------------------------------

CREATE TABLE "user" (
  user_id SERIAL CONSTRAINT ct_user_pk PRIMARY KEY,
  cpf INT8
  	CONSTRAINT ct_user_check_cpf CHECK (check_cpf(cpf)),
  	CONSTRAINT ct_user_cpf_uniqueness UNIQUE (cpf),
  name TEXT CONSTRAINT ct_user_name_not_null NOT NULL,
  email TEXT
    CONSTRAINT ct_user_email_uniqueness UNIQUE,
    CONSTRAINT ct_user_check_email CHECK (email ~ '^.*@.*$'),
  phone TEXT
    CONSTRAINT ct_user_phone_uniqueness UNIQUE,
  	CONSTRAINT ct_user_check_phone_normalization CHECK (phone ~ '^\d+$'),
  hash TEXT
);

CREATE TABLE "book" (
  book_id SERIAL 
    CONSTRAINT ct_book_pk PRIMARY KEY,
  isbn INT8 
    CONSTRAINT ct_book_isbn_not_null NOT NULL,
    CONSTRAINT ct_book_check_isbn CHECK (isbn > 0),
    CONSTRAINT ct_book_isbn_unique UNIQUE (isbn),
  title TEXT 
    CONSTRAINT ct_book_title_not_null NOT NULL,
    CONSTRAINT ct_book_check_title CHECK (title != ''),
  year INT 
    CONSTRAINT ct_book_year_not_null NOT NULL,
    CONSTRAINT ct_book_check_year CHECK (year != 0)
);

CREATE TABLE "publisher" (
  publisher_id SERIAL
    CONSTRAINT ct_publisher_pk PRIMARY KEY,
  name TEXT
    CONSTRAINT ct_publisher_name_not_null NOT NULL,
    CONSTRAINT ct_publisher_check_name CHECK (name != '')
);

CREATE TABLE "author" (
  author_id SERIAL
    CONSTRAINT ct_author_pk PRIMARY KEY,
  name TEXT
    CONSTRAINT ct_author_name_not_null NOT NULL,
    CONSTRAINT ct_author_check_name CHECK (name != ''),
  birth_date DATE
    CONSTRAINT ct_author_birth_date_not_null NOT NULL,
  birthplace TEXT
    CONSTRAINT ct_author_birthplace_not_null NOT NULL,
    CONSTRAINT ct_author_check_birthplace CHECK (birthplace != '')
);

-- relations
CREATE TABLE "write" (
  book_id INT
    CONSTRAINT ct_write_book_fk REFERENCES "book"(book_id),
  author_id INT
    CONSTRAINT ct_write_author_fk REFERENCES "author"(author_id),
  CONSTRAINT ct_write_pk PRIMARY KEY (book_id, author_id)
);

CREATE TABLE "sell" (
  sell_id SERIAL
    CONSTRAINT ct_sell_pk PRIMARY KEY,
  sell_cod TEXT
    CONSTRAINT ct_sell_cod_not_null NOT NULL,
    CONSTRAINT ct_sell_cod_uniqueness UNIQUE (sell_cod),
    CONSTRAINT ct_sell_check_cod CHECK (sell_cod != ''),
  publisher_id INT
    CONSTRAINT ct_sell_publisher_fk REFERENCES "publisher"(publisher_id),
  sale_date DATE
    CONSTRAINT ct_sell_sale_date_not_null NOT NULL,
    CONSTRAINT ct_sell_check_sale_date CHECK (sale_date <= current_date),
  delivery_date DATE
    CONSTRAINT ct_sell_delivery_date_not_null NOT NULL,
    CONSTRAINT ct_sell_check_delivery_date CHECK (delivery_date <= current_date)
);

CREATE TABLE "sale_book" (
  sell_id INT
    CONSTRAINT ct_sale_book_sell_fk REFERENCES "sell"(sell_id) ON DELETE CASCADE,
  book_id INT
    CONSTRAINT ct_sale_book_book_fk REFERENCES "book"(book_id),
  amount INT
    CONSTRAINT ct_sale_book_check_amount CHECK (amount > 0),
  book_price MONEY
    CONSTRAINT ct_sale_book_check_book_price CHECK (book_price > 0.0::money),
  CONSTRAINT ct_sale_book_pk PRIMARY KEY (sell_id, book_id)
);

CREATE TABLE "purchase" (
  purchase_id SERIAL
    CONSTRAINT ct_purchase_pk PRIMARY KEY,
  purchase_cod TEXT
    CONSTRAINT ct_purchase_cod_not_null NOT NULL,
    CONSTRAINT ct_purchase_check_cod CHECK (purchase_cod != ''),
  user_id INT
    CONSTRAINT ct_purchase_user_fk REFERENCES "user"(user_id),
  purchase_date DATE
    CONSTRAINT ct_purchase_date_not_null NOT NULL,
    CONSTRAINT ct_purchase_check_purchase_date CHECK (purchase_date = current_date)
);

CREATE TABLE "purchase_book" (
  purchase_id INT
    CONSTRAINT ct_purchase_book_purchase_fk REFERENCES "purchase"(purchase_id) ON DELETE CASCADE,
  book_id INT
    CONSTRAINT ct_purchase_book_book_fk REFERENCES "book"(book_id),
  amount INT
    CONSTRAINT ct_purchase_book_check_amount CHECK (amount > 0),
  book_price MONEY
    CONSTRAINT ct_purchase_book_check_book_price CHECK (book_price > 0.0::money),
  CONSTRAINT ct_purchase_book_pk PRIMARY KEY (purchase_id, book_id)
);

CREATE TABLE "reserve" (
  reserve_id SERIAL
    CONSTRAINT ct_reserve_pk PRIMARY KEY,
  user_id INT
    CONSTRAINT ct_reserve_user_fk REFERENCES "user"(user_id),
  reserve_date DATE
    CONSTRAINT ct_reserve_date_not_null NOT NULL,
    CONSTRAINT ct_reserve_check_reserve_date CHECK (reserve_date = current_date)
);

CREATE TABLE "reserve_book" (
  reserve_id INT
    CONSTRAINT ct_reserve_book_reserve_fk REFERENCES "reserve"(reserve_id) ON DELETE CASCADE,
  book_id INT
    CONSTRAINT ct_reserve_book_book_fk REFERENCES "book"(book_id),
  amount INT
    CONSTRAINT ct_reserve_book_check_amount CHECK (amount > 0),
  CONSTRAINT ct_reserve_book_pk PRIMARY KEY (reserve_id, book_id)
);

------------------------------------
------------------------------------
--                                --
--          Views                 --
--                                --
------------------------------------
------------------------------------

CREATE VIEW "book_stock" AS 
(
  SELECT b.book_id, sum(coalesce(s.amount, 0)) - sum(coalesce(p.amount, 0)) as amount
  FROM 
    "book" b
    LEFT JOIN "sale_book" s ON s.book_id = b.book_id
    LEFT JOIN "purchase_book" p ON b.book_id = p.book_id
  GROUP BY b.book_id
);

CREATE VIEW "book_availability" AS
(
  SELECT b.book_id, sum(coalesce(s.amount,0)) - sum(coalesce(p.amount, 0)) - sum(coalesce(r.amount, 0)) as amount
  FROM
    "book" b
    LEFT JOIN "sale_book" s ON b.book_id = s.book_id
    LEFT JOIN "purchase_book" p ON b.book_id = p.book_id
    LEFT JOIN 
    (
      SELECT rrr.book_id, rrr.amount FROM "reserve_book" rrr 
        JOIN "reserve" rr ON rr.reserve_id = rrr.reserve_id 
      WHERE rr.reserve_date > (current_date - '7 days'::interval)
    ) r ON b.book_id = r.book_id
  GROUP BY b.book_id
);

CREATE VIEW "balance" AS
(
  SELECT u.day, sum(u.balance) AS balance
  FROM
  (
    SELECT s.sale_date AS day, 0::money - (ss.amount * ss.book_price) AS balance 
      FROM "sale_book" ss JOIN "sell" s ON s.sell_id = ss.sell_id 
    UNION
    SELECT p.purchase_date AS day, (pp.amount * pp.book_price) AS balance 
      FROM "purchase_book" pp JOIN "purchase" p ON p.purchase_id = pp.purchase_id
  ) u GROUP BY u.day
);

------------------------------------
------------------------------------
--                                --
--          Triggers              --
--                                --
------------------------------------
------------------------------------

CREATE FUNCTION hash_password() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.hash IS NOT NULL THEN
    NEW.hash = crypt(NEW.hash, gen_salt('bf', 8));
  END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- password hashing
-- To verify the password use `crypt(<raw_password>, "user".hash)`.
-- 
-- E.g. 
--
--   SELECT 1 FROM "user" u 
--     WHERE u.user_id = <id> 
--       AND u.hash = crypt('<raw_password>', u.hash);
--
--
CREATE TRIGGER tg_user_hash BEFORE INSERT OR UPDATE ON "user"
FOR EACH ROW EXECUTE PROCEDURE hash_password();

CREATE FUNCTION verify_stock() RETURNS TRIGGER AS $$
DECLARE
  stock int;
  u_id int;
  tbl text := quote_ident(TG_TABLE_NAME);
  a INT;
BEGIN
  SELECT amount INTO stock FROM book_availability b WHERE b.book_id = NEW.book_id;
  IF tbl = '"purchase_book"' THEN
    SELECT r.user_id INTO u_id FROM "purchase" r WHERE r.purchase_id = NEW.purchase_id;
    
    SELECT sum(b.amount) INTO a
    FROM "reserve" r
      INNER JOIN "reserve_book" b ON r.reserve_id = b.reserve_id
    WHERE 
      b.book_id = NEW.book_id AND 
      r.user_id = u_id AND 
      r.reserve_date > (current_date - '7 days'::interval)
    GROUP BY b.book_id;
      
  ELSE
    a := 0;
  END IF;
  
  CASE TG_OP
  WHEN 'UPDATE' THEN
    IF NEW.amount - OLD.amount > stock + a THEN
      RAISE EXCEPTION 'No book in stock'; 
      RETURN NULL;
    END IF;
  WHEN 'INSERT' THEN
    IF NEW.amount > stock + a THEN
      RAISE EXCEPTION 'No book in stock';
      RETURN NULL;
    END IF;
  END CASE;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_reserve_book BEFORE INSERT OR UPDATE ON "reserve_book"
FOR EACH ROW EXECUTE PROCEDURE verify_stock();

CREATE TRIGGER tg_purchase_book BEFORE INSERT OR UPDATE ON "purchase_book"
FOR EACH ROW EXECUTE PROCEDURE verify_stock();

CREATE FUNCTION remove_reserve() RETURNS TRIGGER AS $$
DECLARE
a INT;
deleted INT := 0;
res_id INT;
u_id INT;
rec RECORD;
BEGIN

  SELECT p.user_id INTO u_id FROM "purchase" p WHERE p.purchase_id = NEW.purchase_id;

  DROP TABLE IF EXISTS res_info;
  
  CREATE TEMP TABLE res_info ON COMMIT DROP AS  
  SELECT r.reserve_id AS reserve_id, b.amount AS amount
  FROM "reserve" r
    INNER JOIN "reserve_book" b ON r.reserve_id = b.reserve_id
  WHERE 
    b.book_id = NEW.book_id AND 
    r.user_id = u_id AND 
    r.reserve_date > (current_date - '7 days'::interval)
  ORDER BY r.reserve_date;
  
  IF NOT EXISTS (SELECT * FROM res_info) THEN
    RETURN NEW;
  END IF;
  
  FOR rec IN SELECT reserve_id, amount FROM res_info LOOP
    a := rec.amount;
    res_id := rec.reserve_id;
    
    IF NEW.amount - deleted >= a THEN
      deleted := a + deleted;
      DELETE FROM "reserve_book" WHERE reserve_id = res_id AND book_id = NEW.book_id;
      
      IF NOT EXISTS 
      (
        SELECT * FROM "reserve_book" b WHERE b.reserve_id = res_id
      ) THEN
        DELETE FROM "reserve" WHERE reserve_id = res_id;
      END IF;
    ELSE
      IF NEW.amount = deleted THEN
        EXIT;
      END IF;
      UPDATE "reserve_book"
      SET amount = amount - ( NEW.amount - deleted )  
      WHERE reserve_id = res_id AND book_id = NEW.book_id;
      EXIT;
    END IF;
  END LOOP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_remove_reserve_after_purchase AFTER INSERT OR UPDATE ON "purchase_book"
FOR EACH ROW EXECUTE PROCEDURE remove_reserve();

