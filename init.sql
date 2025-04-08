-- Přepnout na správnou databázi
USE zviretnice;

-- Nastavení znakové sady
ALTER DATABASE zviretnice CHARACTER SET utf8mb4 COLLATE utf8mb4_czech_ci;
ALTER DATABASE hlavni CHARACTER SET utf8mb4 COLLATE utf8mb4_czech_ci;

-- Vložení vašeho zvířete
INSERT INTO zvirata (id, jmeno, trida, rad) VALUES ('xlogin00', 'jezevec', 'savci', 'šelmy');

-- Vytvoření pohledu
CREATE OR REPLACE VIEW zvirata_ze_tridy AS
SELECT * FROM zvirata
WHERE trida = (SELECT trida FROM zvirata WHERE id = 'xlogin00');

-- Role
CREATE ROLE trida;
CREATE ROLE rad;

-- Oprávnění rolí
GRANT SELECT ON zviretnice.zvirata_ze_tridy TO trida;
GRANT SELECT, INSERT, UPDATE, DELETE ON zviretnice.vlastnosti_zvirat TO rad;

-- Uživatelské role (příkladoví uživatelé)
CREATE USER 'uzivatel_trida'@'%' IDENTIFIED BY 'heslo';
CREATE USER 'uzivatel_rad'@'%' IDENTIFIED BY 'heslo';

GRANT trida TO 'uzivatel_trida'@'%';
GRANT rad TO 'uzivatel_rad'@'%';

-- Tabulka pro logování úprav
USE hlavni;

CREATE TABLE IF NOT EXISTS upravy_vlastnosti (
    zvire VARCHAR(255),
    vlastnost VARCHAR(255),
    cas TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    uzivatel VARCHAR(255),
    hodnota VARCHAR(255),
    operace ENUM('INSERT', 'DELETE')
);

-- Triggery pro logování
USE zviretnice;

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
