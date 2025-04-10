docker exec -it ads2025 mariadb -u root -p --socket=/run/mysqld/mysqld.sock


SELECT DEFAULT_CHARACTER_SET_NAME, DEFAULT_COLLATION_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'zverinec';

SHOW VARIABLES LIKE 'character_set_database';
SHOW VARIABLES LIKE 'collation_database';

SHOW DATABASES;

ALTER DATABASE hlavni CHARACTER SET utf8mb3 COLLATE utf8mb3_czech_ci;
ALTER DATABASE sys CHARACTER SET utf8mb3 COLLATE utf8mb3_czech_ci;

USE zverinec;

SELECT jmeno_cz FROM zvirata WHERE id = 108666;

ALTER USER 'Irbis'@'%' IDENTIFIED BY 'secret123';

GRANT ALL PRIVILEGES ON *.* TO 'Irbis'@'%';

DELIMITER //
CREATE FUNCTION moje_zvirata_id (input_jmeno_cz VARCHAR(255))
RETURNS INT(11)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE output_zvirata_id INT(11);

    SELECT
        z.id
    INTO
        output_zvirata_id
    FROM
        zvirata z
    WHERE
        z.jmeno_cz = input_jmeno_cz
    LIMIT 1;

    RETURN output_zvirata_id;
END//

CREATE FUNCTION moje_zvirata_trida (input_jmeno_cz VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE output_zvirata_trida VARCHAR(255);

    SELECT
        z.trida
    INTO
        output_zvirata_trida
    FROM
        zvirata z
    WHERE
        z.jmeno_cz = input_jmeno_cz
    LIMIT 1;

    RETURN output_zvirata_trida;
END//

CREATE FUNCTION moje_zvirata_rad (input_jmeno_cz VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE output_zvirata_rad VARCHAR(255);

    SELECT
        z.rad
    INTO
        output_zvirata_rad
    FROM
        zvirata z
    WHERE
        z.jmeno_cz = input_jmeno_cz
    LIMIT 1;

    RETURN output_zvirata_rad;
END //

DELIMITER ;

SELECT moje_zvirata_id('Irbis');
SELECT moje_zvirata_trida('Irbis');
SELECT moje_zvirata_rad('Irbis');

SELECT v.nazev AS nazev_vlastnosti, COUNT(*) AS pocet
FROM zvirata z
JOIN vlastnosti_zvirat vz ON z.id = vz.zvire
JOIN vlastnosti v ON vz.vlastnost = v.id
WHERE z.trida = 'Mammalia - savci'
GROUP BY v.nazev
ORDER BY pocet DESC
LIMIT 5;

CREATE VIEW zvirata_ze_tridy AS
SELECT
    z.id,
    z.jmeno_cz,
    z.rad,
    MAX(CASE WHEN v.nazev = 'Hmotnost' THEN vz.hodnota ELSE NULL END) AS hmotnost,
    MAX(CASE WHEN v.nazev = 'Výskyt' THEN vz.hodnota ELSE NULL END) AS vyskyt,
    MAX(CASE WHEN v.nazev = 'Nadmořská výška' THEN vz.hodnota ELSE NULL END) AS nadmorska_vyska,
    MAX(CASE WHEN v.nazev = 'Povrch' THEN vz.hodnota ELSE NULL END) AS povrch,
    MAX(CASE WHEN v.nazev = 'Světadíl' THEN vz.hodnota ELSE NULL END) AS svetadil
FROM zvirata z
LEFT JOIN vlastnosti_zvirat vz ON z.id = vz.zvire
LEFT JOIN vlastnosti v ON vz.vlastnost = v.id
WHERE z.trida = (SELECT trida FROM zvirata WHERE jmeno_cz = 'Mammalia - savci')
GROUP BY z.id, z.jmeno_cz, z.rad;

CREATE ROLE trida;
CREATE ROLE rad;

GRANT SELECT ON zverinec.zvirata_ze_tridy TO trida;
GRANT SELECT ON zverinec.* TO rad;
GRANT SELECT, INSERT, UPDATE, DELETE ON zverinec.vlastnosti_zvirat TO rad;

USE hlavni;

CREATE TABLE IF NOT EXISTS upravy_vlastnosti (
    zvire VARCHAR(255),
    vlastnost VARCHAR(255),
    cas TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    uzivatel VARCHAR(255),
    hodnota VARCHAR(255),
    operace ENUM('INSERT', 'DELETE')
);

USE zverinec;

DELIMITER //

CREATE TRIGGER log_insert AFTER INSERT ON vlastnosti_zvirat
FOR EACH ROW
BEGIN
    INSERT INTO hlavni.upravy_vlastnosti (zvire, vlastnost, uzivatel, hodnota, operace)
    VALUES (NEW.zvire, NEW.vlastnost, CURRENT_USER(), NEW.hodnota, 'INSERT');
END //

CREATE TRIGGER log_delete AFTER DELETE ON vlastnosti_zvirat
FOR EACH ROW
BEGIN
    INSERT INTO hlavni.upravy_vlastnosti (zvire, vlastnost, uzivatel, hodnota, operace)
    VALUES (OLD.zvire, OLD.vlastnost, CURRENT_USER(), OLD.hodnota, 'DELETE');
END //

DELIMITER ;
