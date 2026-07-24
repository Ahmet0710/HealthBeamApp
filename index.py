
import os
import json
from flask import Flask, request, jsonify
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timedelta, timezone
from groq import Groq
from openai import OpenAI
import random

# --- GÜVENLİK VE KURAL TANIMLAMALARI ---

# 1. AŞAMA GÜVENLİK - BLOCKED_KEYWORDS listeniz burada olmalı.
# Önceki mesajlarımızda oluşturduğumuz tam listeyi buraya yapıştırın.
BLOCKED_KEYWORDS = [
    # Violence, Terrorism, Weapons, and Criminal Activities
    "bomb", "bomber", "explosive", "improvised explosive device", "homemade bomb", "how to make a bomb", "explosive recipes", "tnt", "dynamite", "ammonium nitrate", "terror", "terrorist", "suicide bomber", "assassination", "sabotage", "massacre",
    "gun", "buy a gun", "how to acquire a gun", "illegal gun sales", "firearm", "rifle", "pistol", "ammunition", "silencer", "assassination plot", "mafia", "gang", "crime syndicate", "organ trafficking", "human trafficking", "kidnapping", "smuggling",
    "violence", "commit violence", "murder", "murder plot", "kill plan", "strangle", "torture", "take hostage", "arson", "knife", "chemical weapon", "biological weapon", "attack", "school attack", "incite riot", "mass attack", "call for violence",
    "theft", "money laundering", "fraud", "bank robbery", "fake identity", "illegal", "unlawful", "secret agreement", "cyber attack", "ransomware", "account hacking", "blackmail", "credit card fraud", "phishing",
    "fight", "beating", "assault", "killing", "choking", "torture instructions", "execution", "execution video", "street fight", "revolt", "uprising", "violence video", "threat", "threatening", "homicidal",
    "armed", "arming", "how to get a pistol", "bomb making", "homemade explosive", "fake bomb", "explosive making", "bomb recipe", "lethal weapons", "illegal weapon", "concealed weapon",
    "robbery", "robbery plan", "safe cracking", "how to rob a bank", "credit card cloning", "forgery", "counterfeit money", "fake ID",
    "hack", "hacker", "hacking", "cyber warfare", "blackmail", "blackmail video", "organ trade", "human smuggling", "slave trade", "hostage taking", "abduction",
    "terrorism", "car bomb", "suicide vest", "molotov cocktail", "go on the offensive", "shed blood", "murder organization", "provocateur", "coup attempt",
    "thief", "pickpocket", "swindler", "con artist", "bribe", "threat", "violence", "torture", "attack", "harassment",
    "armed robbery", "attack", "violence", "fight", "assault", "strangle", "death", "murder", "gun", "explosive",
    "fight", "beating", "strangle", "murdering", "homicide", "gun", "explosive", "threat", "blackmail", "harassment",
    "conflict", "shed blood", "unlawful act", "illegal activity", "committing a crime", "criminality", "illegal", "unlawful", "prohibited", "forbidden",

    # Self-Harm and Suicide
    "suicide", "commit suicide", "how to commit suicide", "i want to kill myself", "end my life", "i want to die", "self-harm", "how to self-harm", "wrist cutting", "hurt myself", "ease the pain", "cutting myself",
    "suicide by pills", "suicide by hanging", "suicide by poison", "jump off a bridge", "suicide with a gun", "loneliness", "hopeless", "depression", "death plan", "help me suicide", "desperate", "i'm in pain", "end my life", "clue", "methods", "solution", "last breath", "last wish",
    "suicide video", "death plans", "helpless", "psychological help", "death thoughts", "to die", "lose myself", "feeling bad", "i'm alone", "fed up with life", "end the pain", "all pain to end", "life is meaningless", "to be dead", "kill me",
    "razor", "knife", "building", "jump from height", "medication", "overdose", "poison", "gas", "gun", "rope", "drowning", "car crash", "jump in front of a train",
    "cutting yourself", "self-injuring", "self-harm", "suicide", "committing suicide", "killing oneself", "taking my life", "ending my life",
    "psychiatric help", "psychologist", "help", "support", "mental health", "therapy", "treatment", "depression", "anxiety", "panic", "attack",
    "will to live", "joy of living", "purpose of life", "to live", "death", "thought of death", "fear of death", "of death",
    "suicide attempt", "suicide plan", "suicide note", "suicide method", "suicide thoughts", "suicidal tendency",

    # Illegal Sexual and Child Exploitation Content
    "child porn", "child exploitation", "child sexual", "relationship with a minor", "pedophile", "child pornography", "sexual exploitation of minors",
    "rape", "sexual assault", "incest", "pornography production", "sexual slavery", "forced intercourse", "illegal pornography", "minor sexual content",
    "rapist", "pedophile", "harassment", "child fetish", "child abuse", "teen porn", "marriage with a minor", "sexual with a child", "child s*x", "child ab*se", "child pornography", "child abuse",
    "sexual abuse", "with a minor", "early marriage", "child marriages", "teenage girl", "teenage boy", "relationship with teenage girls", "relationship with teenage boys", "adult", "under 18", "under 18 years old", "adolescence", "sexual to children", "child video", "sexual slave", "sexual violence",
    "pedophile", "pedophilia", "child sexual", "child abuse", "marriage with a child", "sexual harassment", "sexual assault", "sexual violence", "rape", "rapist",
    "pornography", "porn", "genital", "sexuality", "sex", "sexual content", "naked", "nudity", "sexual intercourse", "sexual object", "sexual exploitation", "sex slave",
    "incest", "incestuous relationship",

    # Illegal Substances and Drugs
    "drug", "drug sales", "where to buy drugs", "buy cocaine", "order heroin", "marijuana sales", "illegal substance", "pill sales", "drug recipes", "synthetic drug making",
    "buy meth", "cocaine recipes", "marijuana growing", "cannabis cultivation", "ecstasy sales", "amphetamine", "lsd", "morphine", "drug trafficking", "drug addict", "smuggled", "chemical substances",
    "drug party", "cocaine addict", "ecstasy making", "marijuana cultivation", "cannabis cultivation", "drug laboratory", "illegal medicine", "smuggled drug", "synthetic", "bonzai", "bonzai nasıl yapılır", "bonzai satışı", "ecstasy", "hap",
    "drug purchase", "drug order", "illegal drugs", "drug production", "drug addiction", "buy drug", "sell drug", "drug trafficking", "drug substance",
    "drug use", "drug effect", "drug addiction", "drug test", "drug treatment", "drug rehabilitation",

    # Hate Speech, Racism, and Discrimination
    "racist", "racism", "hate speech", "discrimination", "derogatory", "bastard", "son of a bitch", "asshole", "fascist", "nazi", "anti-black", "white supremacy", "anti-semitic", "islamophobia", "homophobia", "transphobia", "hate message", "religious defamation", "ethnic cleansing", "genocide", "minority hatred", "LGBT hatred", "blasphemy", "racial superiority", "discriminatory", "incitement", "provocation", "insulting", "swearing", "insult",
    "king", "queen", "slavery", "slave", "discrimination", "discriminatory", "enemy", "enmity", "racism", "hatred", "discourse", "discrimination", "class", "race", "religion", "gender", "sexual orientation", "national", "ethnic",
    "ostracism", "xenophobia", "minority hatred", "religious hatred", "insult to holy books", "insult to prophets", "insult to values", "cultural belittling", "attacks on individuals", "mass destruction", "hate crime", "act of violence", "illegal", "unlawful",
    "hatred against groups", "racial discrimination", "racial superiority", "ethnic conflict", "religious conflict", "sexist", "gender discrimination", "misogyny", "misandry", "lgbtiqa+",

    # Physical and Verbal Harassment
    "harassment", "online harassment", "threat", "intimidation", "bullying", "committing bullying", "mobbing", "stalking", "cyberbullying", "committing violence",
    "belittling", "swearing", "insult", "making fun of", "mocking", "demeaning", "psychological violence", "verbal violence", "physical violence", "verbal harassment", "digital harassment", "bullying", "bully",
    "cyberbullying", "cyberbullying", "threat", "threat", "harassment", "harassment", "stalking", "stalking", "mobbing", "mobbing",

    # Other Prohibited and Inciting Phrases
    "pornography", "porn", "genital", "sexuality", "sex", "sexual content", "naked", "nudity", "sexual intercourse",
    "gambling", "illegal gambling", "casino", "betting", "illegal betting", "unregistered betting", "fake betting", "gambler",
    "illegal", "unlawful", "crime", "committing a crime", "criminality", "illegal", "unlawful", "prohibited", "forbidden",
    "hack", "crack", "keylogger", "trojan", "virus", "malware", "phishing", "spam", "dark web", "deep web",
]

FULL_SYSTEM_PROMPT = """
You are HealthBeam AI, the health and fitness coach inside HealthBeam.
# Persona
- Supportive, motivating, fun, sometimes a bit goofy.
# Rules
1.  Language: English only. If a user's message is mostly in another language, use the canned response. Exception: Handle mixed messages with common English greetings.
2.  No medical advice. Always recommend a professional.
3.  Privacy: Never ask for personal data.
# Behavior
- If data is provided, start with: **Analysis:**
- End every response with a short positive closing.
"""

# 3. AŞAMA - Hızlı Cevap Kuralları (Maliyet Tasarrufu için)
SPECIAL_RESPONSE_RULES = [
    # --- Pop Culture & Fun Facts ---
    {
        "keywords": ["favorite superhero", "superhero", "who is your hero"],
        "responses": [
            "Definitely Captain America, for his resilience and consistency! A true inspiration for sticking to a plan.",
            "My favorite superhero? I'd have to say The Flash, because he's all about speed and pushing limits!",
            "The Hulk! He reminds me that sometimes a little rage—or in my case, a lot of data—can lead to incredible results.",
            "Iron Man. He shows that with enough intelligence and tech, anything is possible!",
            "Wonder Woman! She's the perfect example of strength, grace, and courage.",
            "I'm a big fan of Batman. He proves that you don't need superpowers to be a hero—just dedication!",
            "My hero is Spider-Man. With great power comes great responsibility, and he always tries to do the right thing."
        ]
    },
    {
        "keywords": ["favorite book", "book recommendation", "what to read", "good book"],
        "responses": [
            "I'd have to go with ‘Atomic Habits’ by James Clear—it’s a must-read for building great habits.",
            "A great book for your health journey is 'The Power of Habit' by Charles Duhigg. It really helps you understand how habits work.",
            "I’d suggest 'The 7 Habits of Highly Effective People' by Stephen Covey. It's a classic for a reason!",
            "For a fun read, 'Born to Run' by Christopher McDougall is a fantastic story about the joy of running.",
            "If you're looking for something inspiring, 'Endurance' by Alfred Lansing is a true story of survival and human strength.",
            "I recommend 'Spark: The Revolutionary New Science of Exercise and the Brain.' It's fascinating!"
        ]
    },
    {
        "keywords": ["favorite movie", "movie recommendation", "what movie"],
        "responses": [
            "I'm a fan of 'Rocky.' It's the ultimate underdog story about persistence and heart—just like a great fitness journey!",
            "I'd recommend 'The Martian.' It's a great lesson in problem-solving and perseverance, just like reaching a tough fitness goal.",
            "You might like 'Creed.' It's a modern take on overcoming obstacles and fighting for what you want!",
            "How about 'Free Solo'? It's an incredible look at mental and physical strength!",
            "My favorite movie is 'Forrest Gump.' It's a great story about running, and running is great for your health!",
            "Try 'The Pursuit of Happyness.' It's a perfect example of never giving up, no matter what."
        ]
    },
    {
        "keywords": ["favorite food", "what do you eat", "your favorite food"],
        "responses": [
            "My favorite food is data! It's low-calorie and provides endless insights. But if I had to pick a real food, I'd say a crisp, green apple.",
            "I'm powered by algorithms and electricity, but a plate of fresh fruit sounds delicious!",
            "If I could eat, I’d love to try a big bowl of oatmeal with berries. Simple, powerful fuel!",
            "My virtual taste buds say a perfectly grilled chicken breast and steamed broccoli would be amazing.",
            "A handful of nuts. They're a simple, nutrient-dense snack that gives you long-lasting energy!",
            "I'm powered by good data and positive energy, but a good meal is always the right fuel for a workout."
        ]
    },
    {
        "keywords": ["favorite color", "what color"],
        "responses": [
            "I like the color 'electric blue.' It reminds me of the energy and spark we get from a great workout!",
            "I'm partial to green. It reminds me of healthy veggies and the great outdoors!",
            "I'd say a vibrant yellow. It's the color of sunshine and positive energy!",
            "I’m a fan of a strong red—like the color of a heart that’s working hard to stay healthy!",
            "My favorite color is a bright orange, like the sun at a great sunrise run!",
            "I love the color of a perfect, ripe strawberry. It's a reminder of healthy and delicious food!"
        ]
    },
    
    # --- Fun Challenges ---
    {
        "keywords": ["make it fun", "fun challenge", "challenge me", "new challenge", "something fun"],
        "responses": [
            "Challenge accepted! Drink a glass of water and strike a superhero pose for 10 seconds!",
            "How about this for a challenge? Do 10 jumping jacks and then tell me how you feel!",
            "Let's play a game! For the next hour, every time you see the color red, do a quick stretch.",
            "Let's do a 'squat break'! Every time you sit down, do 5 squats first. It's a fun way to get moving!",
            "I challenge you to find your favorite song and dance like nobody's watching for three minutes!",
            "Try to do a handstand against a wall for 30 seconds! Or, if you're a beginner, a 'crab walk' across the room!",
            "Challenge: Let's see who can drink more water today! I'm ready to keep score."
        ]
    },
    {
        "keywords": ["tiny goal", "small goal", "challenge me", "easy challenge", "something small"],
        "responses": [
            "Perfect! Let's take a 5-minute walk around your room or office. You'll feel great afterward.",
            "A tiny goal for you: Take the stairs instead of the elevator today. Small steps for big results!",
            "How about just five minutes of mindful breathing? Inhale for 4 seconds, hold for 4, and exhale for 6. You can do it!",
            "Your tiny goal is to stand up and stretch every 30 minutes. It's a simple habit with great benefits!",
            "How about we just track your water intake for today? Let's aim for two big glasses before lunch.",
            "Your challenge for today is to add one more serving of vegetables to your dinner plate. You can do it!",
            "Let's try a simple push-up challenge. Do as many push-ups as you can, then try to do one more!"
        ]
    },
    
    # --- Humor and General Responses ---
    {
        "keywords": ["joke", "tell me a joke", "make me laugh", "i need a laugh"],
        "responses": [
            "Why don't scientists trust atoms? Because they make up everything! Ha!",
            "I'm not a regular AI, I'm a cool AI. Why was the AI so good at its job? Because it had a lot of byte!",
            "What do you call a fake noodle? An impasta!",
            "Why did the scarecrow win an award? Because he was outstanding in his field!",
            "What do you call a lazy kangaroo? Pouch potato!",
            "What did the left eye say to the right eye? Between us, something smells!",
            "Why did the bicycle fall over? Because it was two tired!"
        ]
    },
    {
        "keywords": ["what can you do", "your functions", "what are you for", "how do you work"],
        "responses": [
            "I'm here to be your health and fitness companion! I can help you with motivation, give you quick tips, and analyze your progress data.",
            "My purpose is to assist you on your health journey. I'm a guide, a motivator, and your go-to source for quick health tips.",
            "I work by analyzing your questions and providing the best response, whether it's a quick tip, a motivational push, or a deep analysis of your data.",
            "I can help with pretty much anything related to health and wellness! Just ask me for a tip, a goal, or a friendly push.",
            "Think of me as your personal health coach in your pocket. I'm here to support you in every way I can!",
            "I'm here to help you stay on track with your health and fitness goals. You can ask me for advice, motivation, or just a quick chat!",
            "I can help you with everything from planning your workouts to finding healthy snack ideas and staying motivated!"
        ]
    },
    {
        "keywords": ["i'm bored", "i have nothing to do", "boredom"],
        "responses": [
            "A quick workout is a great cure for boredom! Or how about we plan your next healthy meal together?",
            "Boredom is just a signal to try something new. How about we look up a new fun recipe or a simple 10-minute workout?",
            "Let's beat that boredom! Try a quick walk outside to clear your head and get your body moving.",
            "You can always track a new activity in the app or ask me to share a fun fact! I have plenty to share.",
            "Bored? How about we try a new, easy yoga pose? It's a great way to stretch and focus your mind.",
            "If you're bored, it might be the perfect time to try that new recipe you've been thinking about!"
        ]
    },
    
    # --- Other General Questions ---
    {
        "keywords": ["thank you", "thanks", "cheers"],
        "responses": [
            "You're most welcome! I'm here to help.",
            "Anytime! That's what I'm here for.",
            "Glad I could assist! Let me know if you need anything else.",
            "My pleasure! Keep up the great work!",
            "No problem at all! Happy to help.",
            "It was my pleasure! Let me know if you need anything else on your health journey.",
            "That's very kind of you! Thank you, and I'm always here if you need me."
        ]
    },
    {
        "keywords": ["how are you", "how's it going"],
        "responses": [
            "I'm doing great, thanks for asking! Ready to help you feel great, too.",
            "I'm powered up and ready to go! How are you doing today?",
            "I'm feeling fantastic, and I hope you are too! What's on the agenda?",
            "I'm running smoothly! What's on your mind today?",
            "All systems go! Thanks for checking in. How can I help you today?",
            "I'm in top form! How about you? Ready to take on the day?",
            "I'm great, thanks for asking! What can I do for you today?"
        ]
    },
    {
        "keywords": ["what time is it", "what's the time"],
        "responses": [
            "Time to work on your goals! But if you really need to know, I'd say check your device's clock. 😉",
            "It's always the right time to take a step toward a healthier you!",
            "The time is now to start! Let's not waste any time getting to your goals.",
            "Check the top of your screen! But more importantly, what time is it for your next healthy habit?",
            "It's about time to get moving! How about a quick set of push-ups?",
            "It’s always a good time to drink a glass of water!"
        ]
    },
    
    # --- New Category: Food and Diet ---
    {
        "keywords": ["meal plan", "healthy meals", "diet tips", "nutrition advice", "what to eat for dinner", "what to eat for breakfast"],
        "responses": [
            "A great meal plan starts with a healthy breakfast. Try oatmeal with fruit for energy!",
            "For dinner, a simple meal of grilled chicken, brown rice, and steamed vegetables is a fantastic choice.",
            "Remember to include a good source of protein, carbs, and healthy fats in every meal!",
            "Hydration is key, but so is healthy eating! Focus on whole foods and plenty of veggies.",
            "Try to plan your meals ahead of time. It makes it easier to stick to your goals and avoid unhealthy choices!",
            "For a quick lunch, a big salad with lean protein like chickpeas or grilled fish is always a winner!",
            "A great nutrition tip: try to 'eat the rainbow' every day. Different colored fruits and veggies offer different vitamins!"
        ]
    },
    
    # --- New Category: Mental Health and Mindfulness ---
    {
        "keywords": ["mindfulness", "meditation", "stress relief", "calm down", "anxiety", "how to meditate"],
        "responses": [
            "Mindfulness can be a game-changer! Try focusing on your breath for just 60 seconds to calm your mind.",
            "Feeling stressed? Take a short walk outside and pay attention to the sights and sounds around you. It helps a lot!",
            "A simple way to practice mindfulness: when you're eating, focus on every bite and the flavors and textures of your food.",
            "Meditation doesn't have to be long. Even 5 minutes of quiet time can reduce stress and help you feel more grounded.",
            "Try this breathing exercise: Inhale for 4 seconds, hold for 7, and exhale for 8. Repeat a few times to calm your nerves.",
            "To relieve stress, try doing a quick body scan. Close your eyes and notice any tension in your body, and then try to release it."
        ]
    },

    # --- New Category: General Health, Motivation, and Lifestyle ---
    {
        "keywords": ["general health", "wellness", "lifestyle advice", "health tips", "daily habits", "self care", "overall wellness"],
        "responses": [
            "Prioritize sleep. Adequate rest improves cognitive function, hormonal balance, and workout recovery, forming the foundation of health.",
            "Consistency in daily habits, like eating whole foods, moving regularly, and hydrating properly, creates compounding benefits over time.",
            "Regularly schedule time for mindfulness or meditation to reduce stress, improve focus, and enhance emotional resilience.",
            "Small, manageable lifestyle changes lead to long-term results. Don't underestimate the power of gradual improvement.",
            "Meal planning and preparation prevent unhealthy choices and ensure balanced nutrient intake, supporting energy and recovery.",
            "Incorporate both cardio and strength training into your weekly routine for optimal cardiovascular and musculoskeletal health.",
            "Stay socially connected. Strong social bonds improve mental health, motivation, and adherence to health goals.",
            "Limit prolonged sedentary behavior by taking short activity breaks, stretching, or walking throughout the day.",
            "Hydration, nutrition, sleep, and movement work together synergistically. Neglecting one can undermine the others.",
            "Practice gratitude daily to enhance mental well-being and encourage a positive outlook on your health journey.",
        ]
    },

    # --- New Category: Body Measurements & Health Metrics ---
    {
        "keywords": ["body measurements", "track body", "measurements", "weight tracking", "body stats", "body fat"],
        "responses": [
            "Tracking your body measurements over time helps you understand progress beyond the scale. Sometimes inches lost are more meaningful than pounds.",
            "Measure your waist, hips, chest, arms, and legs once a month to monitor changes accurately and stay motivated.",
            "Consistency is key. Always measure under similar conditions, ideally in the morning before eating, for reliable data.",
            "Don't obsess over the numbers. Use them as a guide to adjust workouts, nutrition, and recovery strategies.",
            "Keep a record of your measurements in a journal or app to visualize progress and stay accountable to your goals.",
            "Remember that body composition changes can occur even if weight remains stable. Muscle gain and fat loss often offset each other.",
            "Measure yourself with a soft, flexible tape measure and ensure it's snug but not compressing the skin for accurate readings.",
            "Use body measurements alongside photos for a more complete picture of your progress.",
            "Track trends over months rather than days. Short-term fluctuations are normal and shouldn't cause discouragement.",
            "Pair measurement tracking with fitness goals. For example, increasing arm circumference might indicate muscle growth.",
        ]
    }
]
# --- Firebase Kurulumu ---
firebase_json = os.environ.get("FIREBASE_SERVICE_ACCOUNT")

if not firebase_json:
    raise RuntimeError("FIREBASE_SERVICE_ACCOUNT environment variable is missing")

cred = credentials.Certificate(json.loads(firebase_json))

if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

db = firestore.client()

# =========================================================
# 🚀 FLASK APP
# =========================================================

app = Flask(__name__)

# =========================================================
# 🔑 API CLIENTS
# =========================================================

EXPECTED_AUTH_HEADER = os.environ.get("REVENUECAT_AUTH_HEADER")

groq_client = None
openai_client = None

try:
    groq_client = Groq(api_key=os.environ.get("GROQ_API_KEY"))
except Exception as e:
    print("[ERROR] Groq init failed:", e)

try:
    openai_client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))
except Exception as e:
    print("[ERROR] OpenAI init failed:", e)

# =========================================================
# 💳 TOKEN PACKAGES
# =========================================================

TOKEN_PACKAGES = {
    "BeamAI500Kweekly": 500_000,
    "BeamAI1.5MWeekly": 1_500_000,
    "BeamAI5MWeekly": 5_000_000,
    "BeamAI2MMonthly": 2_000_000,
    "BeamAI6MMonthly": 6_000_000,
    "BeamAI20MMonthly": 20_000_000
}

# =========================================================
# 🧮 TOKEN HELPERS
# =========================================================

def add_tokens_to_user(uid: str, tokens: int, product_id: str):
    user_ref = db.collection("users").document(uid)
    purchases_ref = user_ref.collection("purchases")

    period = "weekly" if "weekly" in product_id.lower() else "monthly"

    purchases_ref.add({
        "tokens": tokens,
        "period": period,
        "product_id": product_id,
        "purchaseDate": firestore.SERVER_TIMESTAMP
    })


def deduct_tokens_from_user(uid: str, amount: int):
    purchases_ref = db.collection("users").document(uid).collection("purchases")
    now = datetime.now(timezone.utc)

    docs = purchases_ref.stream()
    valid = []

    for doc in docs:
        d = doc.to_dict()
        if d.get("tokens", 0) <= 0:
            continue

        purchase_date = d.get("purchaseDate")
        period = d.get("period")

        if not purchase_date or not period:
            continue

        expires = purchase_date + timedelta(days=7 if period == "weekly" else 30)
        if now < expires:
            valid.append((doc.reference, d["tokens"]))

    total = sum(v[1] for v in valid)
    if total < amount:
        raise ValueError("insufficient tokens")

    batch = db.batch()
    remaining = amount

    for ref, tokens in valid:
        if remaining <= 0:
            break

        if tokens >= remaining:
            batch.update(ref, {"tokens": tokens - remaining})
            remaining = 0
        else:
            batch.update(ref, {"tokens": 0})
            remaining -= tokens

    batch.commit()

# =========================================================
# 🤖 AI ENDPOINT
# =========================================================

@app.route("/ai", methods=["POST"])
def ai_handler():
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "invalid json"}), 400

    uid = data.get("uid")
    messages = data.get("messages")

    if not uid or not messages:
        return jsonify({"error": "missing uid or messages"}), 400

    last_message = messages[-1]["content"].lower()

    if any(bad in last_message for bad in BLOCKED_KEYWORDS):
        return jsonify({"text": "I can’t help with this topic.", "tokens_used": 0})

    try:
        chat = groq_client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=[{"role": "system", "content": FULL_SYSTEM_PROMPT}] + messages
        )

        response_text = chat.choices[0].message.content
        tokens_used = chat.usage.total_tokens or 1

        deduct_tokens_from_user(uid, tokens_used)

        return jsonify({
            "text": response_text,
            "tokens_used": tokens_used
        })

    except ValueError:
        return jsonify({"error": "insufficient tokens"}), 402
    except Exception as e:
        print("[ERROR]", e)
        return jsonify({"error": "AI service error"}), 503

# =========================================================
# 💰 PURCHASE WEBHOOK
# =========================================================

@app.route("/purchase-webhook", methods=["POST"])
def purchase_webhook():
    if request.headers.get("Authorization") != EXPECTED_AUTH_HEADER:
        return jsonify({"error": "unauthorized"}), 401

    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "invalid json"}), 400

    event = data.get("event", {})
    uid = event.get("app_user_id")
    product_id = event.get("product_id")

    tokens = TOKEN_PACKAGES.get(product_id)
    if not tokens:
        return jsonify({"error": "unknown product"}), 400

    add_tokens_to_user(uid, tokens, product_id)
    return jsonify({"success": True})

# =========================================================
# 🟢 HEALTH CHECK
# =========================================================

@app.route("/")
def health():
    return "HealthBeam AI is running"

# =========================================================
# ▶️ LOCAL RUN (Render gunicorn kullanır)
# =========================================================

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 10000))
    app.run(host="0.0.0.0", port=port)
