# import csv
# import random
# from faker import Faker
#
# # Initialize Faker with multiple locales
# locales = ['it_IT', 'en_US', 'es_ES', 'fr_FR', 'de_DE', 'pt_PT', 'nl_NL']
# fakers = [Faker(locale) for locale in locales]
#
# num_names = 500_000
# filename = 'train_travelers_female_names.csv'
#
# with open(filename, mode='w', newline='', encoding='utf-8') as file:
#     writer = csv.writer(file)
#     writer.writerow(['Name'])
#
#     for _ in range(num_names):
#         faker = random.choice(fakers)
#         name = faker.first_name_female()
#         writer.writerow([name])
#
# print(f'{num_names} male names generated and saved to {filename}')

# import csv
# import random
# from faker import Faker
#
# # Locales
# locales = ['it_IT', 'en_US', 'es_ES', 'fr_FR', 'de_DE', 'pt_PT', 'nl_NL']
# fakers = [Faker(loc) for loc in locales]
#
# num_surnames = 100_000
# filename = 'surnames.csv'
#
# print(f"Generating {num_surnames} surnames (duplicates allowed)...")
#
# with open(filename, mode='w', newline='', encoding='utf-8') as file:
#     writer = csv.writer(file)
#     writer.writerow(['Surname'])
#
#     for i in range(num_surnames):
#         # Pick a random faker from the list
#         fake = random.choice(fakers)
#         # Generate a surname (Faker repeats values from its own data)
#         writer.writerow([fake.last_name()])
#
#         if (i + 1) % 20000 == 0:
#             print(f"Reached {i + 1}...")
#
# print(f"Done! {filename} is ready.")
#
#
# import csv
# import random
# import re
#
#
# def load_csv_list(filename):
#     try:
#         with open(filename, mode='r', encoding='utf-8') as f:
#             reader = csv.reader(f)
#             next(reader)
#             return [row[0].strip() for row in reader if row]
#     except FileNotFoundError:
#         print(f"Error: '{filename}' not found!")
#         return []
#
#
# def clean_for_email(text):
#     clean = text.lower()
#     replacements = {'ë': 'e', 'é': 'e', 'è': 'e', 'à': 'a', 'ò': 'o', 'ç': 'c', 'ì': 'i', 'ù': 'u'}
#     for char, rep in replacements.items():
#         clean = clean.replace(char, rep)
#     clean = re.sub(r'[^a-z0-9]', '', clean)
#     return clean
#
#
# def generate_embg(gender):
#     day = f"{random.randint(1, 28):02d}"
#     month = f"{random.randint(1, 12):02d}"
#     year = str(random.randint(1970, 2005))[1:]
#     registers = ['41', '45', '71', '80', '91', '10', '21', '33', '50']
#     reg = random.choice(registers)
#     pol = f"{random.randint(0, 499):03d}" if gender == 'M' else f"{random.randint(500, 999):03d}"
#     return f"{day}{month}{year}{reg}{pol}{random.randint(0, 9)}"
#
#
# def main():
#     f_names = load_csv_list('train_travelers_girl_names.csv')
#     m_names = load_csv_list('train_travelers_male_names.csv')
#     surnames = load_csv_list('surnames.csv')
#
#     if not f_names or not m_names or not surnames:
#         return
#
#     locales = [
#         ('IT', '39'), ('IT', '39'), ('IT', '39'), ('IT', '39'),
#         ('US', '1'), ('ES', '34'), ('FR', '33'), ('DE', '49'), ('PT', '351'), ('NL', '31')
#     ]
#
#     domains = ['gmail.com', 'yahoo.com', 'outlook.com']
#     all_records = []
#
#     print("Generating 500k profiles...")
#
#     for i in range(500000):
#         gender = 'F' if i < 240000 else 'M'
#         fname = random.choice(f_names if gender == 'F' else m_names)[:20]
#         lname = random.choice(surnames)[:20]
#         embg = generate_embg(gender)
#
#         nat, prefix = random.choice(locales)
#         phone = f"+{prefix}{random.randint(300000000, 399999999)}"
#
#         domain = random.choice(domains)
#         email_prefix = f"{clean_for_email(fname)}.{clean_for_email(lname)}{i}"
#         email = f"{email_prefix}@{domain}"
#
#         if len(email) > 100:
#             email = f"{email_prefix[:50]}@{domain}"
#
#         all_records.append([embg, fname, lname, gender, nat, phone, email])
#
#     print("Shuffling...")
#     random.shuffle(all_records)
#
#     target_file = 'FINAL.csv'
#     with open(target_file, mode='w', newline='', encoding='utf-8') as f:
#         writer = csv.writer(f)
#         writer.writerow(['embg', 'first_name', 'last_name', 'gender', 'nationality', 'phone_number', 'email'])
#         writer.writerows(all_records)
#
#     print("Done!")
#
#
# if __name__ == "__main__":
#     main()


import csv
import random
import re

def load_csv_list(filename):
    try:
        with open(filename, mode='r', encoding='utf-8') as f:
            reader = csv.reader(f)
            next(reader)
            return list(set([row[0].strip() for row in reader if row]))
    except FileNotFoundError:
        print(f"Error: '{filename}' not found!")
        return []

def clean_for_email(text):
    clean = text.lower()
    replacements = {'ë': 'e', 'é': 'e', 'è': 'e', 'à': 'a', 'ò': 'o', 'ç': 'c', 'ì': 'i', 'ù': 'u'}
    for char, rep in replacements.items():
        clean = clean.replace(char, rep)
    clean = re.sub(r'[^a-z0-9]', '', clean)
    return clean or "user"

used_embgs = set()

def generate_unique_embg(gender, i):
    while True:
        day = f"{random.randint(1, 28):02d}"
        month = f"{random.randint(1, 12):02d}"
        year = str(random.randint(1970, 2005))[1:]
        reg = random.choice(['41', '45', '71', '80', '91', '10', '21', '33', '50'])

        pol_val = (i % 500)
        pol = f"{pol_val:03d}" if gender == 'M' else f"{(500 + pol_val):03d}"

        embg = f"{day}{month}{year}{reg}{pol}{random.randint(0, 9)}"

        if embg not in used_embgs:
            used_embgs.add(embg)
            return embg

def main():
    f_names = load_csv_list('train_travelers_female_names.csv')
    m_names = load_csv_list('train_travelers_male_names.csv')
    surnames = load_csv_list('surnames.csv')

    if not f_names or not m_names or not surnames:
        return

    locales = [
        ('IT', '39'), ('US', '1'), ('ES', '34'), ('FR', '33'),
        ('DE', '49'), ('PT', '351'), ('NL', '31')
    ]

    domains = ['gmail.com', 'yahoo.com', 'outlook.com', 'icloud.com']
    all_records = []

    total_records = 1000000
    print(f"Generating {total_records} profiles...")

    for i in range(total_records):
        gender = 'F' if i < (total_records // 2) else 'M'

        fname = random.choice(f_names if gender == 'F' else m_names)[:20]
        lname = random.choice(surnames)[:20]
        embg = generate_unique_embg(gender, i)
        nat, prefix = random.choice(locales)
        phone = f"+{prefix}{random.randint(300000000, 999999999)}"

        domain = random.choice(domains)
        clean_f = clean_for_email(fname)
        clean_l = clean_for_email(lname)

        email = f"{clean_f}.{clean_l}{i}@{domain}"

        all_records.append([embg, fname, lname, gender, nat, phone, email])

        if i % 100000 == 0:
            print(f"Progress: {i}...")

    print("Shuffling everything to mix names and genders...")
    random.shuffle(all_records)

    target_file = 'FINALTABLEPERSON.csv'
    print(f"Saving to {target_file}...")

    with open(target_file, mode='w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['embg', 'first_name', 'last_name', 'gender', 'nationality', 'phone_number', 'email'])
        writer.writerows(all_records)

    print("Done! Total 1,000,000 records generated.")

if __name__ == "__main__":
    main()