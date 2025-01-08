import os
from flask import Flask, render_template, request, jsonify
import mysql.connector
from mysql.connector.errors import DatabaseError
from time import sleep
from enum import Enum
from hashlib import pbkdf2_hmac


class Codes(Enum):
    OK = 0
    NOT_ENOUGH_COFFEE = 1
    STH_ELSE = 999


app = Flask(
    __name__, static_url_path="", static_folder="static", template_folder="templates"
)


class Manager:

    def __init__(self) -> None:

        db_host = "db"
        db_user = os.environ.get("MYSQL_USER")
        db_password = os.environ.get("MYSQL_PASSWORD")
        db_database = os.environ.get("MYSQL_DATABASE")
        db_port = int(os.environ.get("DB_PORT"))

        for _ in range(15):
            try:
                self.connection = mysql.connector.connect(
                    host=db_host,
                    user=db_user,
                    password=db_password,
                    port=db_port,
                    database=db_database,
                )

                self.cursor = self.connection.cursor()

                print("Connected successfully!")
                break
            except Exception as e:
                print(e)
                print("Wainting for database to start up...")
                sleep(1)
        else:
            raise TimeoutError(f"Sth went wrong on {self.__class__.__name__} startup.")

    def __del__(self):
        self.cursor.close()
        self.connection.close()

    def commit_after(method):
        def wrap(self, *args, **kwargs):
            result = method(self, *args, **kwargs)
            self.connection.commit()
            return result

        return wrap

    def get_all_coffee_names(self) -> list[str]:
        self.cursor.execute(
            """
            SELECT
                *
            FROM
                Coffee
            ;
            """
        )

        data = self.cursor.fetchall()
        return [entry[0] for entry in data]

    def get_pwdhash_by_email(self, email: str) -> list[str]:
        self.cursor.execute(
            f"""
            SELECT
                password_hash
            FROM
                Customer
            WHERE
                email = "{email}"
            ;
            """
        )

        data = self.cursor.fetchall()
        return data[0][0]

    @commit_after
    def order_coffee(self, email: str, city: str, coffeeType: str) -> Codes:
        try:

            self.cursor.callproc("OrderCoffee", (email, city, coffeeType))

            return Codes.OK

        except DatabaseError as e:
            if str(e).split()[0] == "1644":
                return Codes.NOT_ENOUGH_COFFEE
            else:
                return Codes.STH_ELSE

    @commit_after
    def add_coffee(self, email: str, city: str, amount: str) -> Codes:

        self.cursor.callproc("AddToCustomerCoffee", (email, city, amount))


class Hasher:

    def __init__(self, min_pwd_len: int, num_iterations=100000) -> None:
        self.min_pwd_len = min_pwd_len
        self.num_iterations = num_iterations

    def hash(self, pwd: str, salt: str) -> tuple[str, str]:

        if len(pwd) < self.min_pwd_len:
            raise ValueError("Password too small!")

        hashed_pwd = pbkdf2_hmac("sha256", pwd.encode(), salt.encode(), 500000).hex()

        return hashed_pwd


manager = Manager()
hasher = Hasher(5)


@app.route("/")
def index():
    coffees = manager.get_all_coffee_names()
    coffee_objects = [{"value": coffee, "name": coffee} for coffee in coffees]
    return render_template("index.html", coffee_objects=coffee_objects)


@app.route("/add_coffee", methods=["POST"])
def handle_addition():
    try:
        data = request.get_json()

        if not data:
            return jsonify({"message": "No data received"}), 400

        email = data.get("email").strip()
        quantity = data.get("quantity").strip()
        city = data.get("city").strip()

        manager.add_coffee(email, city, quantity)

        return jsonify({"message": "Coffee added successfully"}), 200
    except Exception as e:
        return jsonify({"message": "Error processing request"}), 500


@app.route("/order", methods=["POST"])
def handle_order():
    try:
        data = request.get_json()

        if not data:
            return jsonify({"message": "No data received"}), 400

        email = data.get("email").strip()
        password = data.get("password").strip()
        coffeeType = data.get("coffeeType").strip()
        city = data.get("city").strip()

        password_hash = manager.get_pwdhash_by_email(email)

        cur_pwd_hash = hasher.hash(password, email)

        if password_hash != cur_pwd_hash:
            return jsonify({"message": "Incorrect password."}), 403

        result = manager.order_coffee(email, city, coffeeType)

        if result == Codes.OK:
            return jsonify({"message": "Coffee added successfully"}), 200
        elif result == Codes.NOT_ENOUGH_COFFEE:
            return jsonify({"message": "Not enough coffee"}), 499
        else:
            return jsonify({"message": "Error processing request"}), 500
    except Exception as e:
        return jsonify({"message": "Error processing request"}), 500


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=8080)
