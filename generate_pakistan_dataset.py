import csv
import random

# Authentic Pakistani recipes with nutrient values per serving derived from
# Food Composition Table for Pakistan (FCTP, Revised 2001) - UNICEF & NWFP Agricultural University Peshawar

BREAKFASTS = [
    {
        "name": "1 Whole Wheat Chapati with Fried Egg & Doodh Patti Chai",
        "cals": 380, "carbs": 42.0, "protein": 15.5, "fat": 16.0, "sugar": 8.0, "fiber": 3.5, "sodium": 280,
        "calcium": 95, "iron": 2.8, "vitc": 1.0,
        "diet": "Pakistani, Indian, Traditional, Balanced", "suitable_for": "None, Mild", "unsuitable_for": ""
    },
    {
        "name": "2 Boiled Eggs with 2 Brown Bread Toasts & Green Tea",
        "cals": 330, "carbs": 30.0, "protein": 22.0, "fat": 11.5, "sugar": 3.0, "fiber": 4.5, "sodium": 310,
        "calcium": 110, "iron": 3.2, "vitc": 1.5,
        "diet": "Pakistani, Indian, High Protein, Low Carb, Balanced", "suitable_for": "Diabetes, Obesity, Hypertension, Heart Disease", "unsuitable_for": ""
    },
    {
        "name": "1 Crispy Aloo Paratha with Fresh Dahi & Mint Raita",
        "cals": 460, "carbs": 58.0, "protein": 11.0, "fat": 20.0, "sugar": 5.0, "fiber": 4.5, "sodium": 340,
        "calcium": 150, "iron": 3.1, "vitc": 6.0,
        "diet": "Pakistani, Indian, Traditional, Vegetarian", "suitable_for": "None, Mild", "unsuitable_for": "Diabetes, Obesity"
    },
    {
        "name": "Plain Desi Ghee Paratha with Shami Kabab & Chai",
        "cals": 520, "carbs": 44.0, "protein": 21.0, "fat": 28.0, "sugar": 7.0, "fiber": 4.0, "sodium": 420,
        "calcium": 115, "iron": 4.2, "vitc": 2.5,
        "diet": "Pakistani, Indian, Traditional, High Protein", "suitable_for": "None", "unsuitable_for": "Hypertension, Heart Disease, Obesity"
    },
    {
        "name": "Wheat Dalia (Cracked Wheat Porridge in Buffalo Milk)",
        "cals": 310, "carbs": 52.0, "protein": 11.5, "fat": 6.5, "sugar": 12.0, "fiber": 5.5, "sodium": 95,
        "calcium": 240, "iron": 2.2, "vitc": 1.5,
        "diet": "Pakistani, Indian, Vegetarian, Dash, Balanced", "suitable_for": "Hypertension, Heart Disease, Diabetes", "unsuitable_for": ""
    },
    {
        "name": "Halwa Puri with Chana Masala (Sunday Special)",
        "cals": 720, "carbs": 92.0, "protein": 12.0, "fat": 36.0, "sugar": 32.0, "fiber": 5.0, "sodium": 480,
        "calcium": 90, "iron": 3.8, "vitc": 3.0,
        "diet": "Pakistani, Indian, Traditional", "suitable_for": "None", "unsuitable_for": "Diabetes, Obesity, Hypertension, Heart Disease"
    },
    {
        "name": "Anda Ghotala (Spiced Scrambled Eggs) with 1 Tandoori Roti",
        "cals": 410, "carbs": 38.0, "protein": 20.5, "fat": 19.0, "sugar": 4.0, "fiber": 3.8, "sodium": 360,
        "calcium": 85, "iron": 3.5, "vitc": 8.0,
        "diet": "Pakistani, Indian, Traditional, High Protein", "suitable_for": "None, Mild", "unsuitable_for": ""
    },
    {
        "name": "Besan ka Chilla (Savory Gram Flour Pancake) with Mint Dahi",
        "cals": 290, "carbs": 34.0, "protein": 14.5, "fat": 10.0, "sugar": 3.5, "fiber": 6.2, "sodium": 220,
        "calcium": 110, "iron": 3.9, "vitc": 4.5,
        "diet": "Pakistani, Indian, Vegetarian, Low Carb, Dash", "suitable_for": "Diabetes, Obesity, Hypertension", "unsuitable_for": ""
    },
    {
        "name": "Mooli Paratha with Zeera Raita & Chai",
        "cals": 420, "carbs": 52.0, "protein": 9.5, "fat": 18.0, "sugar": 4.0, "fiber": 5.2, "sodium": 320,
        "calcium": 135, "iron": 2.8, "vitc": 12.0,
        "diet": "Pakistani, Indian, Traditional, Vegetarian", "suitable_for": "None, Mild", "unsuitable_for": "Obesity"
    },
    {
        "name": "Oatmeal Porridge in Cow Milk with Sliced Bananas & Almonds",
        "cals": 320, "carbs": 48.0, "protein": 10.5, "fat": 7.0, "sugar": 14.0, "fiber": 6.0, "sodium": 80,
        "calcium": 180, "iron": 2.4, "vitc": 5.0,
        "diet": "Pakistani, Indian, Vegetarian, Balanced, Dash", "suitable_for": "Diabetes, Hypertension, Heart Disease", "unsuitable_for": ""
    }
]

LUNCHES = [
    {
        "name": "Chicken Biryani with Mint Zeera Raita & Fresh Salad",
        "cals": 640, "carbs": 82.0, "protein": 34.0, "fat": 19.5, "sugar": 4.0, "fiber": 3.8, "sodium": 520,
        "calcium": 130, "iron": 3.6, "vitc": 12.0,
        "diet": "Pakistani, Indian, Traditional, Balanced", "suitable_for": "None, Mild", "unsuitable_for": "Diabetes"
    },
    {
        "name": "Daal Masoor Curry with Boiled Basmati Rice & Kachumber",
        "cals": 480, "carbs": 86.0, "protein": 17.5, "fat": 7.0, "sugar": 3.0, "fiber": 8.2, "sodium": 340,
        "calcium": 85, "iron": 4.2, "vitc": 14.0,
        "diet": "Pakistani, Indian, Vegetarian, Low Fat, Dash, Balanced", "suitable_for": "Hypertension, Heart Disease, Kidney Disease", "unsuitable_for": ""
    },
    {
        "name": "Chicken Karahi (200g) with 2 Whole Wheat Chapatis & Salad",
        "cals": 570, "carbs": 58.0, "protein": 44.0, "fat": 17.0, "sugar": 3.5, "fiber": 4.5, "sodium": 440,
        "calcium": 75, "iron": 3.8, "vitc": 16.0,
        "diet": "Pakistani, Indian, High Protein, Traditional", "suitable_for": "Diabetes, Obesity, None", "unsuitable_for": ""
    },
    {
        "name": "Aloo Gosht (Potato Beef Curry) with 1.5 Tandoori Rotis",
        "cals": 560, "carbs": 54.0, "protein": 32.0, "fat": 22.0, "sugar": 4.0, "fiber": 5.0, "sodium": 490,
        "calcium": 65, "iron": 4.5, "vitc": 10.0,
        "diet": "Pakistani, Indian, Traditional, Balanced", "suitable_for": "None, Mild", "unsuitable_for": "Hypertension"
    },
    {
        "name": "Beef Shami Kebab (2 pcs) with 1 Whole Wheat Roti & Salad",
        "cals": 410, "carbs": 38.0, "protein": 30.0, "fat": 14.0, "sugar": 2.5, "fiber": 5.5, "sodium": 380,
        "calcium": 55, "iron": 4.1, "vitc": 8.0,
        "diet": "Pakistani, Indian, High Protein, Low Carb, Balanced", "suitable_for": "Diabetes, Obesity, Hypertension", "unsuitable_for": ""
    },
    {
        "name": "Bhindi Masala (Okra Curry) with 2 Whole Wheat Chapatis",
        "cals": 410, "carbs": 62.0, "protein": 11.5, "fat": 13.0, "sugar": 4.5, "fiber": 9.5, "sodium": 290,
        "calcium": 140, "iron": 3.2, "vitc": 32.0,
        "diet": "Pakistani, Indian, Vegetarian, Dash, Low Fat", "suitable_for": "Diabetes, Hypertension, Heart Disease", "unsuitable_for": ""
    },
    {
        "name": "Lobia / Red Kidney Bean Curry (Kalool) with Zeera Rice",
        "cals": 510, "carbs": 88.0, "protein": 21.0, "fat": 7.5, "sugar": 3.0, "fiber": 11.0, "sodium": 310,
        "calcium": 115, "iron": 4.8, "vitc": 6.5,
        "diet": "Pakistani, Indian, Vegetarian, High Fiber, Dash, Balanced", "suitable_for": "Diabetes, Heart Disease, Hypertension", "unsuitable_for": ""
    },
    {
        "name": "Beef Pulao Gosht with Mint Raita & Sliced Cucumbers",
        "cals": 620, "carbs": 74.0, "protein": 35.0, "fat": 20.0, "sugar": 3.0, "fiber": 3.5, "sodium": 460,
        "calcium": 90, "iron": 4.6, "vitc": 4.0,
        "diet": "Pakistani, Indian, Traditional, Balanced", "suitable_for": "None, Mild", "unsuitable_for": "Hypertension"
    },
    {
        "name": "Kofta Curry (Spiced Meatballs) with 2 Chapatis",
        "cals": 530, "carbs": 52.0, "protein": 36.0, "fat": 18.0, "sugar": 3.5, "fiber": 4.2, "sodium": 450,
        "calcium": 70, "iron": 4.3, "vitc": 8.0,
        "diet": "Pakistani, Indian, High Protein, Traditional", "suitable_for": "None, Mild", "unsuitable_for": ""
    },
    {
        "name": "Daal Channa with 2 Chapatis & Onion Salad",
        "cals": 450, "carbs": 68.0, "protein": 18.0, "fat": 10.0, "sugar": 3.0, "fiber": 8.8, "sodium": 330,
        "calcium": 80, "iron": 3.9, "vitc": 6.0,
        "diet": "Pakistani, Indian, Vegetarian, Balanced, Dash", "suitable_for": "Diabetes, Hypertension, Heart Disease", "unsuitable_for": ""
    }
]

DINNERS = [
    {
        "name": "Chicken Tikka Boti (Grilled) with Mint Raita & Fresh Salad",
        "cals": 360, "carbs": 8.0, "protein": 52.0, "fat": 12.5, "sugar": 2.0, "fiber": 2.5, "sodium": 410,
        "calcium": 95, "iron": 3.2, "vitc": 18.0,
        "diet": "Pakistani, Indian, High Protein, Low Carb, Paleo", "suitable_for": "Diabetes, Obesity, None", "unsuitable_for": ""
    },
    {
        "name": "Peshawari Chapli Kabab with 1 Whole Wheat Roti & Salad",
        "cals": 490, "carbs": 38.0, "protein": 34.0, "fat": 21.0, "sugar": 3.0, "fiber": 4.2, "sodium": 460,
        "calcium": 70, "iron": 4.8, "vitc": 14.0,
        "diet": "Pakistani, Indian, High Protein, Traditional", "suitable_for": "None, Mild", "unsuitable_for": "Hypertension"
    },
    {
        "name": "Beef Nihari with 1 Roghani Naan & Ginger Lemon Garnish",
        "cals": 760, "carbs": 76.0, "protein": 42.0, "fat": 32.0, "sugar": 4.5, "fiber": 4.0, "sodium": 680,
        "calcium": 80, "iron": 5.4, "vitc": 8.0,
        "diet": "Pakistani, Indian, Traditional", "suitable_for": "None", "unsuitable_for": "Hypertension, Heart Disease, Diabetes, Obesity"
    },
    {
        "name": "Machli (Fried Spiced Fish) with 1 Roti & Fresh Lemon",
        "cals": 430, "carbs": 32.0, "protein": 38.0, "fat": 15.0, "sugar": 1.5, "fiber": 2.8, "sodium": 390,
        "calcium": 120, "iron": 2.9, "vitc": 6.0,
        "diet": "Pakistani, Indian, High Protein, Balanced, Mediterranean", "suitable_for": "Heart Disease, Diabetes, Obesity", "unsuitable_for": ""
    },
    {
        "name": "Palak Gosht (Spinach Mutton Curry) with 1.5 Chapatis",
        "cals": 520, "carbs": 48.0, "protein": 33.0, "fat": 21.0, "sugar": 3.2, "fiber": 7.0, "sodium": 420,
        "calcium": 190, "iron": 6.8, "vitc": 28.0,
        "diet": "Pakistani, Indian, Traditional, Balanced", "suitable_for": "None, Mild", "unsuitable_for": ""
    },
    {
        "name": "Mix Sabzi (Carrot, Peas, Potatoes) with 2 Chapatis",
        "cals": 390, "carbs": 66.0, "protein": 11.0, "fat": 10.0, "sugar": 6.0, "fiber": 8.5, "sodium": 280,
        "calcium": 80, "iron": 3.1, "vitc": 36.0,
        "diet": "Pakistani, Indian, Vegetarian, Low Fat, Dash, Balanced", "suitable_for": "Hypertension, Heart Disease, Diabetes", "unsuitable_for": ""
    },
    {
        "name": "Chicken Haleem with 1 Tandoori Naan & Brown Onions",
        "cals": 590, "carbs": 68.0, "protein": 36.0, "fat": 18.0, "sugar": 3.0, "fiber": 8.0, "sodium": 470,
        "calcium": 85, "iron": 4.4, "vitc": 6.0,
        "diet": "Pakistani, Indian, Traditional, High Protein", "suitable_for": "None, Mild", "unsuitable_for": "Hypertension"
    },
    {
        "name": "Balochi Sajji (Roasted Chicken) with 1 cup Zeera Rice",
        "cals": 530, "carbs": 48.0, "protein": 46.0, "fat": 16.0, "sugar": 1.0, "fiber": 2.0, "sodium": 360,
        "calcium": 60, "iron": 3.2, "vitc": 4.0,
        "diet": "Pakistani, Indian, High Protein, Balanced", "suitable_for": "Diabetes, Obesity, Hypertension", "unsuitable_for": ""
    },
    {
        "name": "Anda Curry with 2 Chapatis & Onion Salad",
        "cals": 440, "carbs": 48.0, "protein": 21.0, "fat": 16.0, "sugar": 3.0, "fiber": 4.0, "sodium": 350,
        "calcium": 90, "iron": 3.4, "vitc": 10.0,
        "diet": "Pakistani, Indian, High Protein, Balanced", "suitable_for": "None, Mild", "unsuitable_for": ""
    },
    {
        "name": "Palak Paneer (Spinach with Cottage Cheese) with 2 Chapatis",
        "cals": 460, "carbs": 52.0, "protein": 22.0, "fat": 18.0, "sugar": 3.5, "fiber": 7.5, "sodium": 320,
        "calcium": 280, "iron": 5.5, "vitc": 26.0,
        "diet": "Pakistani, Indian, Vegetarian, Balanced, High Protein", "suitable_for": "Diabetes, Hypertension, Heart Disease", "unsuitable_for": ""
    }
]

SNACKS = [
    {
        "name": "Chana Chaat with Dahi, Onion, Tomato & Tamarind Chutney",
        "cals": 220, "carbs": 38.0, "protein": 9.5, "fat": 3.5, "sugar": 6.0, "fiber": 6.5, "sodium": 280,
        "calcium": 80, "iron": 2.8, "vitc": 12.0,
        "diet": "Pakistani, Indian, Vegetarian, High Fiber, Low Fat, Dash", "suitable_for": "Diabetes, Obesity, Hypertension", "unsuitable_for": ""
    },
    {
        "name": "1 Vegetable Potato Samosa with Mint Green Chutney",
        "cals": 230, "carbs": 26.0, "protein": 4.2, "fat": 12.5, "sugar": 2.0, "fiber": 2.8, "sodium": 260,
        "calcium": 30, "iron": 1.6, "vitc": 4.0,
        "diet": "Pakistani, Indian, Traditional, Vegetarian", "suitable_for": "None", "unsuitable_for": "Obesity, Diabetes, Heart Disease"
    },
    {
        "name": "Dahi Bhalla (Dahi Baray) with Chaat Masala & Papdi",
        "cals": 240, "carbs": 32.0, "protein": 8.0, "fat": 8.5, "sugar": 7.0, "fiber": 3.2, "sodium": 310,
        "calcium": 120, "iron": 1.8, "vitc": 3.5,
        "diet": "Pakistani, Indian, Vegetarian, Balanced", "suitable_for": "None, Mild", "unsuitable_for": ""
    },
    {
        "name": "Roasted Chickpeas (Bhuna Chana - 50g) with Green Tea",
        "cals": 180, "carbs": 29.0, "protein": 10.5, "fat": 2.8, "sugar": 2.0, "fiber": 6.8, "sodium": 90,
        "calcium": 65, "iron": 3.1, "vitc": 1.0,
        "diet": "Pakistani, Indian, High Protein, Low Fat, Dash, Vegetarian", "suitable_for": "Diabetes, Obesity, Hypertension, Heart Disease, Kidney Disease", "unsuitable_for": ""
    },
    {
        "name": "Fresh Fruit Chaat (Apple, Guava, Banana & Chaat Masala)",
        "cals": 130, "carbs": 32.0, "protein": 2.0, "fat": 0.5, "sugar": 22.0, "fiber": 4.8, "sodium": 120,
        "calcium": 35, "iron": 1.2, "vitc": 45.0,
        "diet": "Pakistani, Indian, Low Fat, Dash, Vegetarian", "suitable_for": "Hypertension, Heart Disease, Obesity", "unsuitable_for": ""
    },
    {
        "name": "1 Chicken Shami Kebab with Sliced Cucumber & Mint Raita",
        "cals": 190, "carbs": 12.0, "protein": 18.0, "fat": 7.5, "sugar": 1.5, "fiber": 2.5, "sodium": 240,
        "calcium": 45, "iron": 2.4, "vitc": 5.0,
        "diet": "Pakistani, Indian, High Protein, Low Carb", "suitable_for": "Diabetes, Obesity, Hypertension", "unsuitable_for": ""
    },
    {
        "name": "Doodh Patti Chai with 2 Whole Wheat Rusks",
        "cals": 210, "carbs": 34.0, "protein": 5.5, "fat": 6.0, "sugar": 10.0, "fiber": 2.0, "sodium": 140,
        "calcium": 110, "iron": 1.1, "vitc": 0.5,
        "diet": "Pakistani, Indian, Traditional, Vegetarian", "suitable_for": "None, Mild", "unsuitable_for": ""
    },
    {
        "name": "Gajar ka Halwa (100g Small Cup - Traditional Sweet)",
        "cals": 310, "carbs": 38.0, "protein": 5.2, "fat": 15.0, "sugar": 30.0, "fiber": 2.5, "sodium": 110,
        "calcium": 140, "iron": 1.4, "vitc": 2.0,
        "diet": "Pakistani, Indian, Traditional, Vegetarian", "suitable_for": "None", "unsuitable_for": "Diabetes, Obesity, Heart Disease"
    }
]

def vary_value(val, factor):
    res = val * factor
    return round(res, 2) if isinstance(val, float) else int(round(res))

def generate_dataset(num_rows=2000, output_path="assets/fyp_pakistan_meal_plan.csv"):
    random.seed(42)
    rows = []
    
    headers = [
        "Calories (kcal)",
        "Carbohydrates (g)",
        "Protein (g)",
        "Fats (g)",
        "Free Sugar (g)",
        "Fibre (g)",
        "Sodium (mg)",
        "Breakfast",
        "Lunch",
        "Dinner",
        "Snack",
        "Calcium (mg)",
        "Iron (mg)",
        "Vitamin C (mg)",
        "Disease",
        "Diet Preference"
    ]
    
    for _ in range(num_rows):
        b = random.choice(BREAKFASTS)
        l = random.choice(LUNCHES)
        d = random.choice(DINNERS)
        s = random.choice(SNACKS)
        
        # Portion factor variation (e.g. 0.82 to 1.18) to create rich calorie range
        portion = random.uniform(0.82, 1.18)
        
        tot_cals = vary_value(b["cals"] + l["cals"] + d["cals"] + s["cals"], portion)
        tot_carbs = vary_value(b["carbs"] + l["carbs"] + d["carbs"] + s["carbs"], portion)
        tot_protein = vary_value(b["protein"] + l["protein"] + d["protein"] + s["protein"], portion)
        tot_fat = vary_value(b["fat"] + l["fat"] + d["fat"] + s["fat"], portion)
        tot_sugar = vary_value(b["sugar"] + l["sugar"] + d["sugar"] + s["sugar"], portion)
        tot_fiber = vary_value(b["fiber"] + l["fiber"] + d["fiber"] + s["fiber"], portion)
        tot_sodium = vary_value(b["sodium"] + l["sodium"] + d["sodium"] + s["sodium"], portion)
        tot_calcium = vary_value(b["calcium"] + l["calcium"] + d["calcium"] + s["calcium"], portion)
        tot_iron = vary_value(b["iron"] + l["iron"] + d["iron"] + s["iron"], portion)
        tot_vitc = vary_value(b["vitc"] + l["vitc"] + d["vitc"] + s["vitc"], portion)
        
        # Medical contraindications
        unsuitable_set = set()
        for item in [b, l, d, s]:
            if item["unsuitable_for"]:
                for dis in item["unsuitable_for"].split(','):
                    unsuitable_set.add(dis.strip())
                    
        # Suitable diseases
        diseases_allowed = []
        if "Diabetes" not in unsuitable_set and tot_sugar < 35 and tot_fiber > 20:
            diseases_allowed.append("Diabetes")
        if "Hypertension" not in unsuitable_set and tot_sodium < 1600:
            diseases_allowed.append("Hypertension")
        if "Heart Disease" not in unsuitable_set and tot_fat < 65:
            diseases_allowed.append("Heart Disease")
        if "Obesity" not in unsuitable_set and tot_cals < 2100:
            diseases_allowed.append("Obesity")
        if "Kidney Disease" not in unsuitable_set and tot_protein < 90 and tot_sodium < 1400:
            diseases_allowed.append("Kidney Disease")
            
        disease_str = ", ".join(diseases_allowed) if diseases_allowed else "None"
        
        # Diet Preference tags (Explicitly ensuring Pakistani and Indian are always present)
        is_veg = all("Vegetarian" in item["diet"] for item in [b, l, d, s])
        if is_veg:
            diet_str = "Pakistani, Indian, Vegetarian, Balanced"
        elif tot_protein >= 110:
            diet_str = "Pakistani, Indian, High Protein, Traditional"
        elif tot_carbs <= 170:
            diet_str = "Pakistani, Indian, Low Carb, Traditional"
        elif tot_fat <= 50:
            diet_str = "Pakistani, Indian, Low Fat, Dash, Balanced"
        else:
            diet_str = "Pakistani, Indian, Traditional, Balanced"
            
        row = [
            tot_cals,
            tot_carbs,
            tot_protein,
            tot_fat,
            tot_sugar,
            tot_fiber,
            tot_sodium,
            b["name"],
            l["name"],
            d["name"],
            s["name"],
            tot_calcium,
            tot_iron,
            tot_vitc,
            disease_str,
            diet_str
        ]
        rows.append(row)
        
    with open(output_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(headers)
        writer.writerows(rows)
        
    print(f"✅ Generated {len(rows)} authentic Pakistani meal plans at {output_path}")

if __name__ == "__main__":
    generate_dataset(2000, "assets/fyp_pakistan_meal_plan.csv")
