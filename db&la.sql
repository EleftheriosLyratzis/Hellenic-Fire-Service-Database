CREATE DATABASE PYROSVESTIKOS_STATHMOS;
CREATE TABLE Symvan (
Kodikos_Symvantos INT PRIMARY KEY AUTO_INCREMENT,
Typos VARCHAR(40) NOT NULL,
Topothesia VARCHAR(50) NOT NULL,
Hmerominia_Symvantos DATETIME NOT NULL
);

CREATE TABLE Pyrosvestis (
AM INT PRIMARY KEY AUTO_INCREMENT,
Onoma VARCHAR(50) NOT NULL,
Eponymo VARCHAR(50) NOT NULL,
Vathmos VARCHAR(50) NOT NULL,
Kinito VARCHAR(10)
);
ALTER TABLE Pyrosvestis AUTO_INCREMENT = 1000;

CREATE TABLE Oxima (
Pinakida VARCHAR(7) PRIMARY KEY,
Typos VARCHAR(30) NOT NULL,
Katastasi VARCHAR(30) NOT NULL,
Hmerominia_Teleftaiou_Service DATE
);

CREATE TABLE Antapokrisi (
Kodikos_Antapokrisis INT PRIMARY KEY AUTO_INCREMENT,
Kodikos_Symvantos INT NOT NULL,
Antapokrinomenos_Pyrosvestis INT NOT NULL,
Antapokrinomeno_Oxima VARCHAR(7) NOT NULL,
Ora_Antapokrisis DATETIME NOT NULL,
FOREIGN KEY (Kodikos_Symvantos) REFERENCES Symvan(Kodikos_Symvantos),
FOREIGN KEY (Antapokrinomenos_Pyrosvestis) REFERENCES Pyrosvestis(AM),
FOREIGN KEY (Antapokrinomeno_Oxima) REFERENCES Oxima(Pinakida)
);
ALTER TABLE Antapokrisi AUTO_INCREMENT = 100;

CREATE TABLE Eksoplismos(
Seiriakos_Arithmos VARCHAR(15) PRIMARY KEY,
Eidos VARCHAR(20) NOT NULL,
Anathesi_Se_Oxima VARCHAR(7) NOT NULL,
FOREIGN KEY (Anathesi_Se_Oxima) REFERENCES Oxima(Pinakida)
);

DELIMITER //

CREATE TRIGGER elegxos_katastasis_oximatos_prin_to_insert
BEFORE INSERT ON Antapokrisi
FOR EACH ROW
BEGIN
    DECLARE katastasi_oximatos VARCHAR(30);

    -- Ανάκτηση της κατάστασης του οχήματος που αναφέρεται στην καινούρια εγγραφή
    SELECT Katastasi INTO katastasi_oximatos
    FROM Oxima
    WHERE Pinakida = NEW.Antapokrinomeno_Oxima;

    -- Έλεγχος αν το όχημα είναι σε συντήρηση
    IF katastasi_oximatos = 'ypo_syntirisi' THEN
        -- Σφάλμα αν το όχημα είναι υπό συντήρηση
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Den einai dynati h anathesi oximatos stin antapokrisi: To oxima einai ypo_syntirisi';
    END IF;
END//

DELIMITER ;


DELIMITER //

CREATE TRIGGER Morfi_pinakidas
BEFORE INSERT ON Oxima
FOR EACH ROW
BEGIN
    -- Έλεγχος αν η πινακίδα έχει ακριβώς 4 ψηφία
    IF CHAR_LENGTH(NEW.Pinakida) = 4 AND NEW.Pinakida REGEXP '^[0-9]{4}$' THEN
        -- Προσθήκη του προθέματος "PY-"
        SET NEW.Pinakida = CONCAT('PY-', NEW.Pinakida);
    ELSE
        -- Σφάλμα για λανθασμένη μορφή πινακίδας
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Η Πινακίδα πρέπει να έχει ακριβώς 4 ψηφία χωρίς το πρόθεμα "PY-"';
    END IF;
END//

DELIMITER ;

DELIMITER //

SET GLOBAL event_scheduler = ON;
CREATE EVENT Elegxos_Syntirisis_Oximatos
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
    -- Ενημέρωση κατάστασης οχημάτων σε "Υπό Συντήρηση" εάν έχουν περάσει 365 ημέρες από την τελευταία συντήρηση
    UPDATE Oxima
    SET Katastasi = 'Ypo Syntirisi'
    WHERE DATEDIFF(CURRENT_DATE, Hmerominia_Teleftaiou_Service) > 365;
    
DELIMITER ;

DELIMITER //

CREATE PROCEDURE Prosthiki_Symvantos_Multi_Antapokrisi(
    IN Typos_Symvantos VARCHAR(40),
    IN Topothesia_Symvantos VARCHAR(50),
    IN Hmerominia_Symvantos DATETIME,
    IN Pinakida_Oximatos VARCHAR(7),
    IN Pyrosvestes_Arr TEXT -- Klhsh pyrosveston os text me ta AM xorismena me komma
)
BEGIN
    DECLARE Kodikos_Symvantos INT;
    DECLARE AM_Pyrosvestis INT;
    DECLARE Pyrosvestes_List TEXT;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    ROLLBACK;
    -- Enarksi Transactiion
    START TRANSACTION;

    -- Eisagogi neou Symvantos ston pinaka Symvan
    INSERT INTO Symvan (Typos, Topothesia, Hmerominia_Symvantos)
    VALUES (Typos_Symvantos, Topothesia_Symvantos, Hmerominia_Symvantos);
    -- Apothikefsi Kodikou Symvantos
    SET Kodikos_Symvantos = LAST_INSERT_ID();
    -- Diaxorismos AM Pyrosveston se Array
    SET Pyrosvestes_List = Pyrosvestes_Arr;
    -- Epanalipsi gia kathe pyrosvesti me xrisi ton AM tous
    WHILE LENGTH(Pyrosvestes_List) > 0 DO
        -- Pairnoume to proto AM
        SET AM_Pyrosvestis = SUBSTRING_INDEX(Pyrosvestes_List, ',', 1);
        -- Enimerosi tis listas gia afairaisi tou protou AM
        SET Pyrosvestes_List = SUBSTRING(Pyrosvestes_List, LENGTH(AM_Pyrosvestis) + 2);
        -- Anathesi Pyrosvesti sto Symvan
        INSERT INTO Antapokrisi (Kodikos_Symvantos, Antapokrinomeno_Oxima, Antapokrinomenos_Pyrosvestis, Ora_Antapokrisis)
        VALUES (Kodikos_Symvantos, Pinakida_Oximatos, AM_Pyrosvestis, Hmerominia_Symvantos);
    END WHILE;
    -- An ola pane kala h synalagh epivevaionetai
    COMMIT;
END//

DELIMITER ;

INSERT INTO Pyrosvestis (Onoma, Eponymo, Vathmos, Kinito) VALUES
('Giorgos', 'Papadopoulos', 'Pyrarchos', '6931234567'),
('Alexandros', 'Michaílidis', 'Antipyrarchos', '6932345678'),
('Michalis', 'Vasílakis','Pyragos',  '6933456789'),
('Spyros', 'Georgíou', 'Pyragos', '6934567890'),
('Kostas', 'Konstantínou', 'Ypopyragos', '6935678901'),
('Nikos', 'Antoníou', 'Pyronomos', '6936789012'),
('Thanasis', 'Pappas', 'Pyronomos', '6937890123'),
('Alexandros', 'Dimitriou', 'Archipyrosvestis', '6938901234'),
('Ioannis', 'Christodoulou', 'Archipyrosvestis', '6939012345'),
('Dimitris', 'Nikolaou', 'Pyrosvestis', '6932345671'),
('Giannis', 'Papageorgiou', 'Pyrosvestis', '6933456782'),
('Thodoris', 'Tsioumis', 'Pyrosvestis', '6934567893'),
('Marios', 'Koutsoumpas', 'Pyrosvestis', '6935678904'),
('Kostas', 'Karabatsos', 'Pyrosvestis', '6936789015'),
('Vangelis', 'Makris', 'Pyrosvestis', '6937890126'),
('Sakis', 'Kalogirou', 'Pyrosvestis', '6938901237'),
('Christos', 'Pappas', 'Pyrosvestis', '6939012348'),
('Nikos', 'Kontogiannis', 'Pyrosvestis', '6939123459'),
('Panagiotis', 'Stavropoulos', 'Pyrosvestis', '6930234560');

INSERT INTO Oxima (Pinakida, Typos, Katastasi, Hmerominia_Teleftaiou_Service) VALUES
('1234', 'Diasostiko', 'ok', '2024-10-01'),
('5678', 'Diasostiko', 'ok', '2024-10-15'),
('1111', 'Ydroforo A', 'ok', '2024-09-20'),
('2222', 'Ydroforo A', 'ok', '2024-08-30'),
('3333', 'Ydroforo A', 'ypo_syntirisi', '2023-05-15'),
('4444', 'Ydroforo B', 'ok', '2024-07-01'),
('5555', 'Ydroforo B', 'ok', '2024-06-15'),
('6666', 'Ydroforo B', 'ypo_syntirisi', '2024-12-01'),
('7777', 'Ydroforo C', 'ok', '2024-05-10'),
('8888', 'Ydroforo D', 'ok', '2024-04-05'),
('9999', 'Pick-up', 'ok', '2024-03-15'),
('1010', 'Pick-up', 'ypo_syntirisi', '2024-11-20'),
('2020', 'Van', 'ok', '2024-02-10'),
('3030', 'Van', 'ok', '2024-01-25'),
('4040', 'Klimakoforo', 'ok', '2024-03-01'),
('5050', 'Asthenoforo', 'ok', '2024-02-05'),
('6060', 'Epivatiko', 'ok', '2024-03-12');

INSERT INTO Eksoplismos (Seiriakos_Arithmos, Eidos, Anathesi_Se_Oxima) VALUES
('AV001', 'Farmakeio', 'PY-1234'), ('AV002', 'Farmakeio', 'PY-5678'), ('AV003', 'Farmakeio', 'PY-1111'), 
('AV004', 'Farmakeio', 'PY-2222'), ('AV005', 'Farmakeio', 'PY-3333'), ('AV006', 'Farmakeio', 'PY-4444'), 
('AV007', 'Farmakeio', 'PY-5555'), ('AV008', 'Farmakeio', 'PY-6666'), ('AV009', 'Farmakeio', 'PY-7777'), 
('AV010', 'Farmakeio', 'PY-8888'), ('AV011', 'Farmakeio', 'PY-9999'), ('AV012', 'Farmakeio', 'PY-1010'), 
('AV013', 'Farmakeio', 'PY-2020'), ('AV014', 'Farmakeio', 'PY-3030'), ('AV015', 'Farmakeio', 'PY-4040'), 
('AV016', 'Farmakeio', 'PY-5050'), ('AV017', 'Farmakeio', 'PY-6060');

INSERT INTO Eksoplismos (Seiriakos_Arithmos, Eidos, Anathesi_Se_Oxima) VALUES
('AN001', 'Antlia', 'PY-1111'), ('SL001', 'Solinas 25mm', 'PY-1111'), ('SL002', 'Solinas 25mm', 'PY-1111'), ('SL003', 'Solinas 25mm', 'PY-1111'),
('SL004', 'Solinas 25mm', 'PY-1111'), ('SL005', 'Solinas 45mm', 'PY-1111'), ('SL006', 'Solinas 45mm', 'PY-1111'), ('SL007', 'Solinas 65mm', 'PY-1111'), 
('AL001', 'Avlos 25mm', 'PY-1111'), ('AL002', 'Avlos 25mm', 'PY-1111'), ('AL003', 'Avlos 45mm', 'PY-1111'), ('AL004', 'Avlos 65mm', 'PY-1111'), 
('AS001', 'Anapnefstiki Syskevi', 'PY-1111'), ('AS002', 'Anapnefstiki Syskevi', 'PY-1111'), ('AS003', 'Anapnefstiki Syskevi', 'PY-1111'), ('AS004', 'Anapnefstiki Syskevi', 'PY-1111'), 
('SY001', 'Systoli 65mm-45mm', 'PY-1111'), ('SY002', 'Systoli 45mm-25mm', 'PY-1111'), ('DI001', 'Dikrouno', 'PY-1111'), ('DI002', 'Dikrouno', 'PY-1111'), 
('TR001', 'Trikrouno', 'PY-1111'), ('KL001', 'Kleidia', 'PY-1111'),  ('AP001', 'Alysopriono', 'PY-1111');

INSERT INTO Eksoplismos (Seiriakos_Arithmos, Eidos, Anathesi_Se_Oxima) VALUES
('AN002', 'Antlia', 'PY-4444'), 
('SL008', 'Solinas 25mm', 'PY-4444'), ('SL009', 'Solinas 25mm', 'PY-4444'), ('SL010', 'Solinas 25mm', 'PY-4444'), ('SL011', 'Solinas 25mm', 'PY-4444'), 
('SL012', 'Solinas 45mm', 'PY-4444'), ('SL013', 'Solinas 45mm', 'PY-4444'), ('SL014', 'Solinas 65mm', 'PY-4444'), 
('AL005', 'Avlos 25mm', 'PY-4444'), ('AL006', 'Avlos 25mm', 'PY-4444'), ('AL007', 'Avlos 45mm', 'PY-4444'), ('AL008', 'Avlos 65mm', 'PY-4444'), 
('AS005', 'Anapnefstiki Syskevi', 'PY-4444'), ('AS006', 'Anapnefstiki Syskevi', 'PY-4444'), ('AS007', 'Anapnefstiki Syskevi', 'PY-4444'), ('AS008', 'Anapnefstiki Syskevi', 'PY-4444'), 
('SY003', 'Systoli 65mm-45mm', 'PY-4444'), ('SY004', 'Systoli 45mm-25mm', 'PY-4444'), ('DI003', 'Dikrouno', 'PY-4444'), ('DI004', 'Dikrouno', 'PY-4444'),
 ('TR002', 'Trikrouno', 'PY-4444'), ('KL002', 'Kleidia', 'PY-4444'), ('AP002', 'Alysopriono', 'PY-4444');

INSERT INTO Eksoplismos (Seiriakos_Arithmos, Eidos, Anathesi_Se_Oxima) VALUES
('AN003', 'Antlia', 'PY-7777'), 
('SL015', 'Solinas 25mm', 'PY-7777'), ('SL016', 'Solinas 25mm', 'PY-7777'), ('SL017', 'Solinas 25mm', 'PY-7777'), ('SL018', 'Solinas 25mm', 'PY-7777'), 
('SL019', 'Solinas 45mm', 'PY-7777'), ('SL020', 'Solinas 45mm', 'PY-7777'), ('SL021', 'Solinas 65mm', 'PY-7777'), 
('AL009', 'Avlos 25mm', 'PY-7777'), ('AL010', 'Avlos 25mm', 'PY-7777'), ('AL011', 'Avlos 45mm', 'PY-7777'), ('AL012', 'Avlos 65mm', 'PY-7777'), 
('AS009', 'Anapnefstiki Syskevi', 'PY-7777'), ('AS010', 'Anapnefstiki Syskevi', 'PY-7777'), ('AS011', 'Anapnefstiki Syskevi', 'PY-7777'), ('AS012', 'Anapnefstiki Syskevi', 'PY-7777'), 
('SY005', 'Systoli 65mm-45mm', 'PY-7777'), ('SY006', 'Systoli 45mm-25mm', 'PY-7777'), 
('DI005', 'Dikrouno', 'PY-7777'), ('DI006', 'Dikrouno', 'PY-7777'), 
('TR003', 'Trikrouno', 'PY-7777'), ('KL003', 'Kleidia', 'PY-7777'),  ('AP003', 'Alysopriono', 'PY-7777');

INSERT INTO Eksoplismos (Seiriakos_Arithmos, Eidos, Anathesi_Se_Oxima) VALUES
('AN004', 'Antlia', 'PY-8888'), 
('SL022', 'Solinas 25mm', 'PY-8888'), ('SL023', 'Solinas 25mm', 'PY-8888'), ('SL024', 'Solinas 25mm', 'PY-8888'), ('SL025', 'Solinas 25mm', 'PY-8888'), 
('SL026', 'Solinas 45mm', 'PY-8888'), ('SL027', 'Solinas 45mm', 'PY-8888'), ('SL028', 'Solinas 65mm', 'PY-8888'), 
('AL013', 'Avlos 25mm', 'PY-8888'), ('AL014', 'Avlos 25mm', 'PY-8888'), ('AL015', 'Avlos 45mm', 'PY-8888'), ('AL016', 'Avlos 65mm', 'PY-8888'), 
('AS013', 'Anapnefstiki Syskevi', 'PY-8888'), ('AS014', 'Anapnefstiki Syskevi', 'PY-8888'), ('AS015', 'Anapnefstiki Syskevi', 'PY-8888'), ('AS016', 'Anapnefstiki Syskevi', 'PY-8888'), 
('SY007', 'Systoli 65mm-45mm', 'PY-8888'), ('SY008', 'Systoli 45mm-25mm', 'PY-8888'), 
('DI007', 'Dikrouno', 'PY-8888'), ('DI008', 'Dikrouno', 'PY-8888'), 
('TR004', 'Trikrouno', 'PY-8888'), ('KL004', 'Kleidia', 'PY-8888'), ('AP004', 'Alysopriono', 'PY-8888');

INSERT INTO Eksoplismos (Seiriakos_Arithmos, Eidos, Anathesi_Se_Oxima) VALUES
('AN005', 'Antlia', 'PY-4040'), 
('SL029', 'Solinas 25mm', 'PY-4040'), ('SL030', 'Solinas 25mm', 'PY-4040'), ('SL031', 'Solinas 25mm', 'PY-4040'), ('SL032', 'Solinas 25mm', 'PY-4040'), 
('SL033', 'Solinas 45mm', 'PY-4040'), ('SL034', 'Solinas 45mm', 'PY-4040'), ('SL035', 'Solinas 65mm', 'PY-4040'),('AL017', 'Avlos 25mm', 'PY-4040'),
('AL018', 'Avlos 25mm', 'PY-4040'), ('AL019', 'Avlos 45mm', 'PY-4040'), ('AL020', 'Avlos 65mm', 'PY-4040'), ('AS017', 'Anapnefstiki Syskevi', 'PY-4040'),
('AS018', 'Anapnefstiki Syskevi', 'PY-4040'), ('SY009', 'Systoli 65mm-45mm', 'PY-4040'), ('SY010', 'Systoli 45mm-25mm', 'PY-4040'), ('DI009', 'Dikrouno', 'PY-4040'),
('TR005', 'Trikrouno', 'PY-4040'), ('KL005', 'Kleidia', 'PY-4040'), ('AP005', 'Alysopriono', 'PY-4040');

INSERT INTO Eksoplismos (Seiriakos_Arithmos, Eidos, Anathesi_Se_Oxima) VALUES
('AN006', 'Antlia', 'PY-2222'), 
('SL036', 'Solinas 25mm', 'PY-2222'), ('SL037', 'Solinas 25mm', 'PY-2222'), ('SL038', 'Solinas 25mm', 'PY-2222'), ('SL039', 'Solinas 25mm', 'PY-2222'), 
('SL040', 'Solinas 45mm', 'PY-2222'), ('SL041', 'Solinas 45mm', 'PY-2222'), ('SL042', 'Solinas 65mm', 'PY-2222'),('AL021', 'Avlos 25mm', 'PY-2222'),
('AL022', 'Avlos 25mm', 'PY-2222'), ('AL023', 'Avlos 45mm', 'PY-2222'), ('AL024', 'Avlos 65mm', 'PY-2222'), ('AS019', 'Anapnefstiki Syskevi', 'PY-2222'),
('AS020', 'Anapnefstiki Syskevi', 'PY-2222'), ('SY011', 'Systoli 65mm-45mm', 'PY-2222'), ('SY012', 'Systoli 45mm-25mm', 'PY-2222'), ('DI010', 'Dikrouno', 'PY-2222'),
('TR006', 'Trikrouno', 'PY-2222'), ('KL006', 'Kleidia', 'PY-2222'), ('AP006', 'Alysopriono', 'PY-2222');

CALL Prosthiki_Symvantos_Multi_Antapokrisi(
    'Dasiki Pyrkagia',
    'Athina',
    '2024-11-01 08:30:00',
    'PY-2222',
    '1000,1001,1002'
);
CALL Prosthiki_Symvantos_Multi_Antapokrisi(
    'Dasiki Pyrkagia',
    'Thessloniki',
    '2024-11-08 09:00:00',
    'PY-5555',
    '1003,1004,1005'
);

CALL Prosthiki_Symvantos_Multi_Antapokrisi(
    'Troxaio',
    'Kavala',
    '2024-11-12 19:30:00',
    'PY-5678',
    '1006,1007,1008'
);
-- Apostoli enisxyseon
INSERT INTO Antapokrisi (Kodikos_Symvantos, Antapokrinomenos_Pyrosvestis, Antapokrinomeno_Oxima, Ora_Antapokrisis) VALUES
('3',1001,'PY-1234','2024-11-12 20:00:00'),('3',1010,'PY-1234','2024-11-12 20:00:00');

CALL Prosthiki_Symvantos_Multi_Antapokrisi(
    'Dasiki Pykagia',
    'Heraklio',
    '2024-10-05 10:00:00',
    'PY-6666',
    '1009,1010,1011'
);

INSERT INTO Symvan (Typos, Topothesia, Hmerominia_Symvantos) VALUES
('Antlisi Ydaton','Chrysoupoli','2024-11-15 09:00:00');
INSERT INTO Antapokrisi (Kodikos_Symvantos, Antapokrinomenos_Pyrosvestis, Antapokrinomeno_Oxima, Ora_Antapokrisis) VALUES
('5',1005,'PY-4444','2024-11-15 09:00:00'),('5',1015,'PY-4444','2024-11-15 09:05:00');

INSERT INTO Symvan (Typos, Topothesia, Hmerominia_Symvantos) VALUES
('Antlisi Ydaton','Chrysoupoli','2024-11-15 11:30:00');
INSERT INTO antapokrisi (Kodikos_Symvantos, Antapokrinomenos_Pyrosvestis, Antapokrinomeno_Oxima, Ora_Antapokrisis) VALUES
('6',1006,'PY-2222','2024-11-15 09:00:00'),('6',1014,'PY-2222','2024-11-15 11:35:00');

-- Ypologizei ton arithmo symmetoxon kathe pyrosvesti se diaforetika symvanta kai emfanizei kai ton vathmo tou
SELECT Pyrosvestis.AM, Pyrosvestis.Onoma, Pyrosvestis.Eponymo, Pyrosvestis.Vathmos, COUNT(Antapokrisi.Kodikos_Antapokrisis) AS Sinolikes_Symmetoxes
FROM Pyrosvestis, Antapokrisi
WHERE Pyrosvestis.AM = Antapokrisi.Antapokrinomenos_Pyrosvestis
GROUP BY Pyrosvestis.AM, Pyrosvestis.Vathmos;

-- Emfanizei monadika kathe kommati eksoplismou ana oxima pou symmetixe se symvanta, mazi me ton typo tou symvantos
SELECT DISTINCT Eksoplismos.Seiriakos_Arithmos, Eksoplismos.Eidos AS Eidos_Eksoplismou, Oxima.Pinakida, Symvan.Typos AS Typos_Symvantos
FROM Eksoplismos, Oxima, Symvan, Antapokrisi
WHERE Eksoplismos.Anathesi_Se_Oxima = Oxima.Pinakida
  AND Oxima.Pinakida = Antapokrisi.Antapokrinomeno_Oxima
  AND Symvan.Kodikos_Symvantos = Antapokrisi.Kodikos_Symvantos;

-- Emfanizei plirofories gia ta symvanta kai tous pyrosvestes pou antapokrithikan se auta
SELECT 
    Symvan.Kodikos_Symvantos,
    Symvan.Typos AS Typos_Symvantos,
    Symvan.Topothesia,
    GROUP_CONCAT(Pyrosvestis.AM, ' ', Pyrosvestis.Onoma, ' ', Pyrosvestis.Eponymo ORDER BY Pyrosvestis.AM SEPARATOR ', ') AS Pyrosvestes
FROM Symvan, Pyrosvestis, Antapokrisi
WHERE Symvan.Kodikos_Symvantos = Antapokrisi.Kodikos_Symvantos
  AND Pyrosvestis.AM = Antapokrisi.Antapokrinomenos_Pyrosvestis
GROUP BY Symvan.Kodikos_Symvantos, Symvan.Typos, Symvan.Topothesia;

-- Parexei leptomereies gia ta oximata pou antapokrithikan se diafora symvanta
SELECT DISTINCT
    Symvan.Kodikos_Symvantos,
    Symvan.Typos AS Typos_Symvantos,
    Symvan.Hmerominia_Symvantos,
    GROUP_CONCAT(DISTINCT Oxima.Pinakida, ' ', Oxima.Typos ORDER BY Oxima.Pinakida SEPARATOR ', ') AS Oxima
FROM Symvan, Oxima, Antapokrisi
WHERE Symvan.Kodikos_Symvantos = Antapokrisi.Kodikos_Symvantos
  AND Oxima.Pinakida = Antapokrisi.Antapokrinomeno_Oxima
GROUP BY Symvan.Kodikos_Symvantos, Symvan.Typos, Symvan.Hmerominia_Symvantos;

-- Emfanizei ta stoixeia tou oxhmatos me vazi tin pinakida pou theloume
DELIMITER //

CREATE PROCEDURE pliroforiesOximatos(
    IN Pinakida_Oximatos VARCHAR(7)
)
BEGIN
    SELECT *
    FROM Oxima
    WHERE Pinakida_Oximatos = Pinakida;
    IF ROW_COUNT() = 0 THEN
        SELECT CONCAT('Δεν βρέθηκε Όχημα με την πινακίδα "', Pinakida_Oximatos, '".') AS Message;
    END IF;
END//

DELIMITER ;

CALL pliroforiesOximatos('PY-1010');