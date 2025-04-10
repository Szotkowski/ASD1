import mariadb

db_config = {
    "host": "localhost",
    "port": 3360,
    "user": "root",
    "password": "root",
    "database": "zverinec"
}

try:
    mydb = mariadb.connect(**db_config)
    mycursor = mydb.cursor()

    zvire_jmeno = 'Irbis'
    mycursor.execute("SELECT trida, rad FROM zvirata WHERE jmeno_cz = %s", (zvire_jmeno,))
    zvire_info = mycursor.fetchone()

    if zvire_info:
        zvire_trida = zvire_info[0]
        zvire_rad = zvire_info[1]

        role_trida = zvire_trida.lower().replace(' ', '_')
        role_rad = zvire_rad.lower().replace(' ', '_')

        mycursor.execute(f"CREATE ROLE IF NOT EXISTS '{role_trida}'")
        mycursor.execute(f"CREATE ROLE IF NOT EXISTS '{role_rad}'")
        mydb.commit()

        mycursor.execute("SELECT jmeno_cz FROM zvirata")
        zvirata_jmena = [row[0] for row in mycursor.fetchall()]

        mycursor.execute("SELECT User FROM mysql.user")
        mysql_uzivatele = [row[0] for row in mycursor.fetchall()]

        for uzivatel in mysql_uzivatele:
            if uzivatel in zvirata_jmena:
                mycursor.execute("SELECT trida, rad FROM zvirata WHERE jmeno_cz = %s", (uzivatel,))
                uzivatel_zvire_info = mycursor.fetchone()

                if uzivatel_zvire_info:
                    uzivatel_trida = uzivatel_zvire_info[0]
                    uzivatel_rad = uzivatel_zvire_info[1]

                    uzivatel_role_trida = uzivatel_trida.lower().replace(' ', '_')
                    uzivatel_role_rad = uzivatel_rad.lower().replace(' ', '_')

                    if uzivatel_trida == zvire_trida:
                        mycursor.execute(f"GRANT '{role_trida}' TO '{uzivatel}'@'%'")
                        print(f"Uživateli '{uzivatel}' byla přidělena role '{role_trida}'.")

                    if uzivatel_rad == zvire_rad:
                        mycursor.execute(f"GRANT '{role_rad}' TO '{uzivatel}'@'%'")
                        print(f"Uživateli '{uzivatel}' byla přidělena role '{role_rad}'.")
            else:
                mycursor.execute(f"UPDATE mysql.user SET Host = 'localhost' WHERE User = '{uzivatel}' AND Host != 'localhost'")
                print(f"Uživateli '{uzivatel}' byla omezena možnost přihlášení na localhost.")

        mydb.commit()

    mydb.close()

except mariadb.Error as err:
    print(f"Error: {err}")