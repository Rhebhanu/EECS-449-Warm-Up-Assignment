walker interact {
    can return_message with `root entry {
        report {
            "response": "Hello, world!"
        };
    }
}

walker interact_with_body {
    has name: str;

    can return_message with `root entry {
        report {
            "response": "Hello, " + self.name + "!"
        };
    }
}

walker calculate_difference {
    has a: int;
    has b: int;

    can return_message with `root entry {
        report {
            "response": "The difference of " + str(self.a) + " and " + str(self.b) + " is " + str(self.a - self.b) + "."
        };
    }
}

walker calculate_sum {
    has a: int;
    has b: int;

    can return_message with `root entry {
        report {
            "response": "The sum of " + str(self.a) + " and " + str(self.b) + " is " + str(self.a + self.b) + "."
        };
    }
}
