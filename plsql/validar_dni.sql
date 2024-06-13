CREATE OR REPLACE FUNCTION letra_dni(numero_dni int4) 
RETURNS char AS 
$$
    DECLARE 
        letra_a_devolver char(1);
    BEGIN
        SELECT Letra INTO letra_a_devolver 
        FROM   Letras_DNI
        WHERE  RESTO = MOD(numero_dni, 23);
        return letra_a_devolver;
    END;
$$ LANGUAGE plpgsql;
-- Función que puede usarse en triggers
-- Tenemos a nuestra disposición 2 variables:
--   - NEW <- La fila que inserto o valor nuevo (en un update)
--   - OLD <- En un update, el valor anterior (el que voy a reemplazar)
CREATE OR REPLACE FUNCTION validar_letra() 
RETURNS trigger AS 
$$
    BEGIN
        IF ( NEW.LETRA_DNI <> letra_dni(NEW.NUMERO_DNI) ) THEN
            RAISE EXCEPTION 'Letra de control del DNI incorrecta';
        END IF;
        return NEW;
    END;
$$ LANGUAGE plpgsql;
-- cada vez que se haga un INSERT o un UPDATE en la tabla Personas, 
-- verifiquemos la letra del DNI y el número antes de su modificación/inserción
                                -- AFTER / BEFORE  
CREATE TRIGGER validador_letra_dni BEFORE INSERT OR UPDATE ON Personas
FOR EACH ROW EXECUTE PROCEDURE validar_letra();