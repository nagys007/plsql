CREATE OR REPLACE FUNCTION f_vin_check ( p_vin IN VARCHAR2 )
RETURN VARCHAR2
IS
  -- https://en.wikipedia.org/wiki/Vehicle_identification_number
  c_length CONSTANT PLS_INTEGER DEFAULT 17; -- expected length of a VIN
  c_pos CONSTANT PLS_INTEGER DEFAULT 9; -- position of a checksum character
  l_expected VARCHAR2(1);
  l_calculated VARCHAR2(1);
  l_multipliers VARCHAR2(17);
  l_multiplier CHAR(1);
  c_weights CONSTANT VARCHAR2(17) DEFAULT '8765432A098765432';
  l_weight CHAR(1);
  l_sum PLS_INTEGER;
BEGIN
  IF p_vin IS NULL OR p_vin = '' THEN RETURN 'ERROR: VIN is empty'; END IF;
  IF LENGTH(p_vin) < c_length THEN RETURN 'ERROR: VIN is too short; expected '|| c_length ||' chars'; END IF;
  IF LENGTH(p_vin) > c_length THEN RETURN 'ERROR: VIN is too long; expected '|| c_length ||' chars'; END IF;
  IF p_vin != UPPER(p_vin) THEN RETURN 'ERROR: VIN contains lower case letters'; END IF;
  IF REGEXP_LIKE(p_vin,'.*[IOQ]+.*') THEN RETURN 'ERROR: VIN contains invalid letters I/Q/O'; END IF;
  --
  l_expected := SUBSTR(p_vin,c_pos,1);
  l_calculated := '?';
  l_multipliers := TRANSLATE(p_vin,
                  'ABCDEFGH JKLMN P RSTUVWXYZ1234567890',
                  '12345678 12345 7 9234567891234567890');
  --dbms_output.put_line(l_multipliers);
  l_sum := 0;
  FOR i IN 1 .. LENGTH(l_multipliers)
  LOOP
    l_weight := SUBSTR(c_weights,i,1);
    l_multiplier := SUBSTR(l_multipliers,i,1);
    IF l_multiplier NOT IN ('0','1','2','3','4','5','6','7','8','9')
    THEN RETURN 'ERROR: VIN contains invalid (non-alpha-numeric) characters'; END IF;
    l_sum := l_sum + TO_NUMBER(l_multiplier) 
    * CASE l_weight WHEN 'A' THEN 10 ELSE TO_NUMBER(l_weight) END;
  END LOOP;
  IF MOD(l_sum,11) = 10 THEN l_calculated := 'X';
  ELSE l_calculated := TO_CHAR(MOD(l_sum,11)); END IF;
  IF l_expected = l_calculated THEN RETURN 'OK'; END IF;
  IF l_expected != l_calculated THEN RETURN 'ERROR: invalid checksum; expected '
  || l_expected ||', calculated '|| l_calculated; END IF;
  --
  RETURN 'ERROR: code should never be reached';
EXCEPTION WHEN OTHERS
THEN
  DBMS_OUTPUT.PUT_LINE(SQLCODE);
  DBMS_OUTPUT.PUT_LINE(SQLERRM);
  RETURN 'FAILURE';
END f_vin_check;
/
