from hashlib import pbkdf2_hmac


class Hasher:

    def __init__(self, min_pwd_len: int, num_iterations=100000) -> None:
        self.min_pwd_len = min_pwd_len
        self.num_iterations = num_iterations

    def hash(self, pwd: str, salt: str) -> tuple[str, str]:

        if len(pwd) < self.min_pwd_len:
            raise ValueError("Password too small!")

        hashed_pwd = pbkdf2_hmac("sha256", pwd.encode(), salt.encode(), 500000).hex()

        return hashed_pwd



hasher = Hasher(5)
print(
    hasher.hash(
        "12345", "garry.garry@example.com"
    )
)