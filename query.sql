SELECT * FROM "book_stock";

SELECT insert_sell(s.c, s.p, s.sd::date, s.dd::date, s.bb::int[], s.aa::int[], s.pcpc::numeric[]::money[]) FROM
(VALUES
  ('SEL1', 1, '2017-10-01', '2017-10-17', '{1,   2}', 
                                          '{40,  100}',
                                          '{10,  30}')
) AS s (c, p, sd, dd, bb, aa, pcpc);

SELECT * FROM "book_stock";

-- buying unavailable book
SELECT 'buying unavailable book. Must raise error.';
BEGIN;
SELECT insert_purchase(s.c, s.u, s.d::date, s.bb::int[], s.aa::int[], s.pcpc::numeric[]::money[]) FROM
(VALUES
  ('PUR1', 1, current_date, '{3}', 
                            '{1}',
                            '{30}')
) AS s (c, u, d, bb, aa, pcpc);
ROLLBACK;

SELECT * FROM "book_stock";

-- buying available books
SELECT 'buying many available book';

SELECT insert_reserve(s.u, s.d::date, s.bb::int[], s.aa::int[]) FROM
(VALUES
  (1, current_date, '{1,   2}', 
                    '{1,   2}')
) AS s (u, d, bb, aa);

SELECT * FROM "reserve";

SELECT insert_purchase(s.c, s.u, s.d::date, s.bb::int[], s.aa::int[], s.pcpc::numeric[]::money[]) FROM
(VALUES
  ('PUR1', 1, current_date, '{1,   2}', 
                            '{1,   3}',
                            '{30,  35}')
) AS s (c, u, d, bb, aa, pcpc);

SELECT * FROM "book_stock";


SELECT * FROM "balance";
