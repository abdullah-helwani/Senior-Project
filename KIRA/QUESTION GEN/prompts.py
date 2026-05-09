"""
All prompts in English and Arabic.
The LLM receives the prompt in the same language as the document.
"""

# ── Bloom's taxonomy descriptions ────────────────────────────────────────────

BLOOM_EN = {
    "remember":  "Recall facts and basic concepts (e.g., Define, List, Name, Who, What, When).",
    "understand":"Explain ideas or concepts in your own words (e.g., Summarize, Describe, Explain, Classify).",
    "apply":     "Use information in new situations (e.g., Calculate, Solve, Use, Demonstrate).",
    "analyze":   "Draw connections and break down information (e.g., Compare, Contrast, Examine, Differentiate).",
    "evaluate":  "Justify a decision or course of action (e.g., Argue, Judge, Defend, Justify, Critique).",
    "create":    "Produce new or original work (e.g., Design, Construct, Develop, Formulate, Propose).",
}

BLOOM_AR = {
    "remember":  "تذكّر الحقائق والمفاهيم الأساسية (مثل: عرّف، اذكر، سمّ، من، ما، متى).",
    "understand":"شرح الأفكار بأسلوبك الخاص (مثل: لخّص، اوصف، اشرح، صنّف).",
    "apply":     "توظيف المعلومات في مواقف جديدة (مثل: احسب، حلّ، طبّق، بيّن).",
    "analyze":   "تحليل المعلومات وربطها (مثل: قارن، فرّق، افحص، حلّل).",
    "evaluate":  "تقييم وإصدار أحكام مبررة (مثل: ناقش، قيّم، دافع، انتقد).",
    "create":    "إنتاج أعمال أو أفكار جديدة (مثل: صمّم، ابنِ، طوّر، اقترح).",
}

# ── Question type instructions ────────────────────────────────────────────────

TYPE_INSTRUCTIONS_EN = {
    "mcq": """Generate a Multiple Choice Question (MCQ):
- One clear question
- 4 options labeled A, B, C, D
- Exactly one correct answer
- 3 plausible but clearly wrong distractors
- Provide the correct answer letter and a brief explanation""",

    "true_false": """Generate a True/False question:
- One clear statement that is definitively true or false
- Provide the correct answer (True or False)
- Provide a brief explanation""",

    "short_answer": """Generate a Short Answer question:
- One clear question requiring a 1-3 sentence answer
- Provide a model answer""",

    "fill_blank": """Generate a Fill in the Blank question:
- One sentence with one key word/phrase replaced by _______
- The blank must be a meaningful, specific term from the text
- Provide the correct answer""",

    "essay": """Generate an Essay question:
- One open-ended question requiring a detailed paragraph or more
- Provide key points that a good answer should cover""",
}

TYPE_INSTRUCTIONS_AR = {
    "mcq": """أنشئ سؤال اختيار من متعدد (MCQ):
- سؤال واضح ومحدد
- 4 خيارات مسماة بـ A وB وC وD
- إجابة صحيحة واحدة فقط
- 3 خيارات خاطئة ولكن معقولة
- اذكر حرف الإجابة الصحيحة مع شرح مختصر""",

    "true_false": """أنشئ سؤال صح أم خطأ:
- جملة واضحة تكون إما صحيحة أو خاطئة بشكل قاطع
- اذكر الإجابة (صح أو خطأ) مع شرح مختصر""",

    "short_answer": """أنشئ سؤال إجابة قصيرة:
- سؤال واضح يتطلب إجابة من 1-3 جمل
- قدّم نموذج إجابة""",

    "fill_blank": """أنشئ سؤال ملء الفراغ:
- جملة واحدة تحتوي على فراغ _______ يمثل مصطلحاً أساسياً
- اذكر الإجابة الصحيحة""",

    "essay": """أنشئ سؤال مقالي:
- سؤال مفتوح يتطلب إجابة تفصيلية
- اذكر النقاط الرئيسية التي يجب أن تتضمنها الإجابة الجيدة""",
}

# ── Difficulty ────────────────────────────────────────────────────────────────

DIFFICULTY_EN = {
    "easy":   "The question should be straightforward and suitable for basic recall.",
    "medium": "The question should require some thinking and understanding.",
    "hard":   "The question should be challenging and require deep understanding or analysis.",
}

DIFFICULTY_AR = {
    "easy":   "يجب أن يكون السؤال مباشراً ومناسباً للتذكر الأساسي.",
    "medium": "يجب أن يتطلب السؤال بعض التفكير والفهم.",
    "hard":   "يجب أن يكون السؤال صعباً ويتطلب فهماً عميقاً أو تحليلاً.",
}

# ── JSON output format instructions ──────────────────────────────────────────

JSON_FORMAT_EN = {
    "mcq": """{
  "type": "mcq",
  "bloom_level": "<level>",
  "difficulty": "<difficulty>",
  "question": "<question text>",
  "options": {"A": "...", "B": "...", "C": "...", "D": "..."},
  "correct_answer": "<A|B|C|D>",
  "explanation": "<why this answer is correct>"
}""",

    "true_false": """{
  "type": "true_false",
  "bloom_level": "<level>",
  "difficulty": "<difficulty>",
  "question": "<statement>",
  "correct_answer": "<True|False>",
  "explanation": "<explanation>"
}""",

    "short_answer": """{
  "type": "short_answer",
  "bloom_level": "<level>",
  "difficulty": "<difficulty>",
  "question": "<question>",
  "model_answer": "<expected answer>"
}""",

    "fill_blank": """{
  "type": "fill_blank",
  "bloom_level": "<level>",
  "difficulty": "<difficulty>",
  "question": "<sentence with _______>",
  "correct_answer": "<the missing word/phrase>"
}""",

    "essay": """{
  "type": "essay",
  "bloom_level": "<level>",
  "difficulty": "<difficulty>",
  "question": "<essay question>",
  "key_points": ["point 1", "point 2", "point 3"]
}""",
}

# Arabic format uses same structure, LLM fills content in Arabic
JSON_FORMAT_AR = JSON_FORMAT_EN


# ── Prompt builders ───────────────────────────────────────────────────────────

def build_prompt(
    context:     str,
    question_type: str,
    bloom_level: str,
    difficulty:  str,
    language:    str,          # "ar" or "en"
    question_num: int = 1,
) -> tuple[str, str]:
    """
    Returns (system_prompt, user_prompt) for the LLM.
    """
    is_arabic = language == "ar"

    bloom_desc  = (BLOOM_AR if is_arabic else BLOOM_EN).get(bloom_level, "")
    type_instr  = (TYPE_INSTRUCTIONS_AR if is_arabic else TYPE_INSTRUCTIONS_EN).get(question_type, "")
    diff_desc   = (DIFFICULTY_AR if is_arabic else DIFFICULTY_EN).get(difficulty, "")
    json_format = (JSON_FORMAT_AR if is_arabic else JSON_FORMAT_EN).get(question_type, "")

    if is_arabic:
        system = (
            "You are an expert educator creating high-quality exam questions. "
            "The question content and answers must be written in Arabic. "
            "CRITICAL: You must respond with valid JSON only — no extra text, no markdown. "
            "CRITICAL: All JSON keys must be in English exactly as shown in the format below. "
            "Only the values (question text, answers, explanations) should be in Arabic."
        )
        user = f"""Reference text (Arabic):
\"\"\"
{context}
\"\"\"

Task: Generate question number {question_num} with these specifications:

Question type: {type_instr}

Bloom's level: {bloom_level} — {bloom_desc}

Difficulty: {difficulty} — {diff_desc}

Rules:
- The question MUST be based strictly on the reference text above.
- Write all question text, options, and explanations in Arabic.
- Use ONLY English key names in the JSON (question, options, correct_answer, explanation, etc.).
- Do not invent information not present in the text.

Respond with JSON only, using this EXACT format with English keys:
{json_format}"""

    else:
        system = (
            "You are an expert educator specialized in creating high-quality exam questions. "
            "Your task is to generate exam questions based strictly on the provided text. "
            "You follow Bloom's Taxonomy for educational objectives. "
            "Always respond with valid JSON only — no extra text, no markdown code blocks."
        )
        user = f"""Reference text:
\"\"\"
{context}
\"\"\"

Task: Generate question number {question_num} with the following specifications:

Question type: {type_instr}

Bloom's level: {bloom_level} — {bloom_desc}

Difficulty: {difficulty} — {diff_desc}

The question must be directly based on the information in the reference text above.
Do not invent information that is not in the text.

Respond with JSON only in this exact format:
{json_format}"""

    return system, user
