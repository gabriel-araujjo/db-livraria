CREATE FUNCTION insert_book(i INT8, t TEXT, y INT, aa INT[]) RETURNS void AS $$
DECLARE
  id INT;
  a INT;
BEGIN

  INSERT INTO "book"(isbn, title, year)
  VALUES (i, t, y) RETURNING book_id INTO id;
  
  FOREACH a IN ARRAY aa
  LOOP
    INSERT INTO "write"(book_id, author_id) VALUES (id, a);
  END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION insert_sell(c TEXT, p INT, sd DATE, dd DATE, bb INT[], aa INT[], pcpc MONEY[]) RETURNS void AS $$
DECLARE
  id INT;
  i INT;
BEGIN

  INSERT INTO "sell"(sell_cod, publisher_id, sale_date, delivery_date)
  VALUES (c, p, sd, dd) RETURNING sell_id INTO id;
  
  FOR i IN 1 .. array_upper(bb, 1)
  LOOP
    INSERT INTO "sale_book"(sell_id, book_id, amount, book_price) VALUES (id, bb[i], aa[i], pcpc[i]);
  END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION insert_purchase(c TEXT, u INT, d DATE, bb INT[], aa INT[], pcpc MONEY[]) RETURNS void AS $$
DECLARE
  id INT;
  i INT;
BEGIN

  INSERT INTO "purchase"(purchase_cod, user_id, purchase_date)
  VALUES (c, u, d) RETURNING purchase_id INTO id;
  
  FOR i IN 1 .. array_upper(bb, 1)
  LOOP
    INSERT INTO "purchase_book"(purchase_id, book_id, amount, book_price) VALUES (id, bb[i], aa[i], pcpc[i]);
  END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION insert_reserve(u INT, d DATE, bb INT[], aa INT[]) RETURNS void AS $$
DECLARE
  id INT;
  i INT;
BEGIN

  INSERT INTO "reserve"(user_id, reserve_date) VALUES (u, d) RETURNING reserve_id INTO id;
  
  FOR i IN 1 .. array_upper(bb, 1)
  LOOP
    INSERT INTO "reserve_book"(reserve_id, book_id, amount) VALUES (id, bb[i], aa[i]);
  END LOOP;
END;
$$ LANGUAGE plpgsql;

INSERT INTO author (name, birth_date, birthplace) VALUES
('Joaquim Manuel de Macedo', '1820-06-24', 'Itaboraí, RJ'),
('José de Alencar',          '1829-05-01', 'Fortaleza, CE'),
('Machado de Assis',         '1839-06-21', 'Rio de Janeiro, RJ');

SELECT insert_book(b.i, b.t, b.y, b.aa::int[]) FROM 
(VALUES
  (8525406546, 'A Moreninha',                     1844, '{1}'),
  (8525044652, 'Memórias Póstumas de Brás Cubas', 1881, '{3}'),
  (8574803243, 'Iracema',                         1865, '{2}')
) AS b (i, t, y, aa);

INSERT INTO publisher (name) VALUES
('Companhia das letras'),
('Rocco');

INSERT INTO "user" (cpf, name, email, phone, hash) VALUES
(83482239320, 'José da Silva', 'j123@email.com', '234234334', '123456'),
(91722888253, 'Maria Pereira', 'm123@email.com', '676626622', '123456');

