# main.py
import sys
import os

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from src.kumo import HomeScreen


def main():
    home = HomeScreen()
    home.run()


if __name__ == "__main__":
    main()
