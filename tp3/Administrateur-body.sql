CREATE OR REPLACE PACKAGE BODY Administrateur AS
	PROCEDURE OuvrirVol (
		p_numero VOL.NUMERO%TYPE,
		p_date_depart VOL.DEPART%TYPE,
		p_date_arrivee VOL.ARRIVEE%TYPE,
		p_ville_depart Ville.NOM%TYPE,
		p_ville_arrivee Ville.NOM%TYPE,
		p_compagnie Compagnie_Aerienne.NOM%TYPE
	) AS
		v_id_compagnie          Compagnie_Aerienne.ID%TYPE;
		v_aeroport_depart       Aeroport.ID%TYPE;
		v_aeroport_arivee       Aeroport.ID%TYPE;
		v_statut_ouvert         STATUT.ID%TYPE;
			depart_notfound         EXCEPTION;
			arrivee_notfound        EXCEPTION;
			compagnie_notfound      EXCEPTION;
	BEGIN

		-- Check if compagnie exist
		BEGIN
			SELECT ID into v_id_compagnie FROM Compagnie_Aerienne WHERE NOM = p_compagnie;
			EXCEPTION
			WHEN NO_DATA_FOUND THEN
			raise compagnie_notfound;
		END;


		-- Check if ville depart exist
		BEGIN
			SELECT A.ID INTO v_aeroport_depart
			FROM Aeroport A, Ville_Desservie VD, VILLE V
			WHERE A.ID = VD.AEROPORT AND VD.VILLE = V.ID AND V.NOM = p_ville_depart;
			EXCEPTION
			WHEN NO_DATA_FOUND THEN
			raise depart_notfound;
		END;

		-- Check if ville arrivee exist
		BEGIN
			SELECT A.ID INTO v_aeroport_arivee
			FROM Aeroport A, Ville_Desservie VD, VILLE V
			WHERE A.ID = VD.AEROPORT AND VD.VILLE = V.ID AND V.NOM = p_ville_arrivee;
			EXCEPTION
			WHEN NO_DATA_FOUND THEN
			raise arrivee_notfound;
		END;

		SELECT ID INTO v_statut_ouvert FROM STATUT WHERE LIBELLE LIKE '%Ouvert%';
		dbms_output.put_line('ID : ' || v_statut_ouvert);

		INSERT INTO VOL(ID, NUMERO, COMPAGNIE, DEPART, ARRIVEE, AEROPORT_DEPART, AEROPORT_ARRIVE, STATUT)
		VALUES ((Select max(id)+1 from vol), p_numero, v_id_compagnie, TO_DATE(p_date_depart, 'DD/mm/YYYY'), TO_DATE(p_date_arrivee, 'DD/mm/YYYY'), v_aeroport_depart, v_aeroport_arivee, v_statut_ouvert);

		EXCEPTION
		WHEN depart_notfound THEN
		dbms_output.put_line('Votre ville de depart n existe pas ou ne possede pas d aeroport');
		WHEN arrivee_notfound THEN
		dbms_output.put_line('Votre ville d arrivee n existe pas ou ne possede pas d aeroport');
		WHEN compagnie_notfound THEN
		dbms_output.put_line('Compagnie non trouvee');
	END OuvrirVol;
	------------------------------------------------------------

	FUNCTION avgVol(p_classe Classe.LIBELLE%TYPE)
	RETURN PLS_INTEGER IS
		moyenne PLS_INTEGER;
	BEGIN
		SELECT AVG(P.PRIX) INTO moyenne
		FROM Place P, Vol V, Statut S, Classe C
		WHERE P.VOL = V.ID AND V.STATUT = S.ID AND S.LIBELLE LIKE '%Ouvert%'
		      AND P.CLASSE = C.ID AND C.LIBELLE = p_classe;
		RETURN moyenne;
	END avgVol;

	PROCEDURE ListerVolsPlusChersAVG (
		p_classe Classe.LIBELLE%TYPE
	) AS
		moyenne PLS_INTEGER;
	BEGIN
		moyenne := avgVol(p_classe);
		FOR rec IN (
		SELECT V.*
		FROM Vol V, PLACE P, STATUT S, CLASSE C
		WHERE V.ID = P.VOL AND P.CLASSE = C.ID AND C.LIBELLE = p_classe
		      AND V.STATUT = S.ID AND S.LIBELLE LIKE '%Ouvert%'
		      AND P.Prix > moyenne
		) LOOP
			dbms_output.put_line(rec.NUMERO || ' ' || rec.COMPAGNIE || ' ' || rec.DEPART || ' ' || rec.ARRIVEE
			                     || ' ' || rec.AEROPORT_DEPART || ' ' || rec.AEROPORT_ARRIVE || ' ' || rec.STATUT);
		END LOOP;

	END;

END Administrateur;
/

SHOW ERRORS;

