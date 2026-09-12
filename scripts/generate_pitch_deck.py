#!/usr/bin/env python3
"""
XonaDosh Super-Simple, Visual, High-Impact Pitch Deck
8 Slides, Minimal Text, Real Photos, Big Typography.
10% Equity Max ($50,000 @ $500,000 Valuation).
"""

import os
import sys
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.enum.shapes import MSO_SHAPE

# Brand Palette
C_BG = RGBColor(6, 20, 15)            # Deep Emerald Dark
C_CARD = RGBColor(12, 34, 26)         # Dark Green Card
C_CARD_ALT = RGBColor(18, 52, 40)     # Accent Card
C_EMERALD = RGBColor(16, 185, 129)    # Emerald Green
C_EMERALD_DARK = RGBColor(5, 150, 105)# Deep Green
C_MINT = RGBColor(167, 243, 208)      # Mint
C_WHITE = RGBColor(255, 255, 255)     # Pure White
C_MUTED = RGBColor(148, 163, 184)     # Slate
C_GOLD = RGBColor(245, 158, 11)       # Amber Gold
C_RED = RGBColor(239, 68, 68)         # Red
C_BORDER = RGBColor(22, 60, 46)       # Border

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOGO_PATH = os.path.join(ROOT_DIR, 'assets', 'brand', 'xonadosh_logo_ui.png')
ICON_PATH = os.path.join(ROOT_DIR, 'assets', 'brand', 'xonadosh_icon.png')
IMG_HERO = os.path.join(ROOT_DIR, 'assets', 'pitch', 'hero.jpg')
IMG_PROBLEM = os.path.join(ROOT_DIR, 'assets', 'pitch', 'problem.jpg')
IMG_MATCH = os.path.join(ROOT_DIR, 'assets', 'pitch', 'match.jpg')
IMG_KITCHEN = os.path.join(ROOT_DIR, 'assets', 'pitch', 'kitchen.jpg')

DIST_DIR = os.path.join(ROOT_DIR, 'dist')
PITCH_WEB_DIR = os.path.join(ROOT_DIR, 'backend', 'pitch')

os.makedirs(DIST_DIR, exist_ok=True)
os.makedirs(PITCH_WEB_DIR, exist_ok=True)

prs = Presentation()
prs.slide_width = Inches(13.333)
prs.slide_height = Inches(7.5)
blank_layout = prs.slide_layouts[6]

def create_slide():
    slide = prs.slides.add_slide(blank_layout)
    bg = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, 0, 0, prs.slide_width, prs.slide_height)
    bg.fill.solid()
    bg.fill.fore_color.rgb = C_BG
    bg.line.fill.background()
    return slide

def add_header(slide, tag, title, sub=None):
    pill = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(0.8), Inches(0.4), Inches(2.8), Inches(0.35))
    pill.fill.solid()
    pill.fill.fore_color.rgb = C_CARD
    pill.line.color.rgb = C_EMERALD_DARK
    tf = pill.text_frame
    tf.vertical_anchor = MSO_ANCHOR.MIDDLE
    p = tf.paragraphs[0]
    p.alignment = PP_ALIGN.CENTER
    r = p.add_run()
    r.text = tag.upper()
    r.font.bold = True
    r.font.size = Pt(11)
    r.font.color.rgb = C_EMERALD

    tb = slide.shapes.add_textbox(Inches(0.8), Inches(0.8), Inches(11.7), Inches(0.7))
    tf2 = tb.text_frame
    tf2.word_wrap = True
    p2 = tf2.paragraphs[0]
    r2 = p2.add_run()
    r2.text = title
    r2.font.bold = True
    r2.font.size = Pt(28)
    r2.font.color.rgb = C_WHITE

    if sub:
        p3 = tf2.add_paragraph()
        r3 = p3.add_run()
        r3.text = sub
        r3.font.size = Pt(14)
        r3.font.color.rgb = C_MUTED

    if os.path.exists(ICON_PATH):
        try:
            slide.shapes.add_picture(ICON_PATH, Inches(12.1), Inches(0.4), width=Inches(0.45))
        except Exception:
            pass

def add_card(slide, left, top, width, height, title, subtitle=None, bullets=None, accent=C_EMERALD, highlight=False):
    shape = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(left), Inches(top), Inches(width), Inches(height))
    shape.fill.solid()
    shape.fill.fore_color.rgb = C_CARD_ALT if highlight else C_CARD
    shape.line.color.rgb = accent if highlight else C_BORDER
    shape.line.width = Pt(1.5 if highlight else 1)

    tf = shape.text_frame
    tf.word_wrap = True
    tf.margin_left = Inches(0.25)
    tf.margin_right = Inches(0.25)
    tf.margin_top = Inches(0.2)

    p0 = tf.paragraphs[0]
    r0 = p0.add_run()
    r0.text = title
    r0.font.bold = True
    r0.font.size = Pt(18)
    r0.font.color.rgb = accent

    if subtitle:
        p_sub = tf.add_paragraph()
        p_sub.space_before = Pt(2)
        r_sub = p_sub.add_run()
        r_sub.text = subtitle
        r_sub.font.bold = True
        r_sub.font.size = Pt(22)
        r_sub.font.color.rgb = C_WHITE

    if bullets:
        for b in bullets:
            p = tf.add_paragraph()
            p.space_before = Pt(4)
            r = p.add_run()
            r.text = b
            r.font.size = Pt(13)
            r.font.color.rgb = C_WHITE if highlight else C_MUTED
    return shape

def add_stat(slide, left, top, width, height, num, label, sub=None, color=C_EMERALD):
    shape = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(left), Inches(top), Inches(width), Inches(height))
    shape.fill.solid()
    shape.fill.fore_color.rgb = C_CARD
    shape.line.color.rgb = C_BORDER
    tf = shape.text_frame
    tf.word_wrap = True
    tf.margin_top = Inches(0.2)

    p0 = tf.paragraphs[0]
    p0.alignment = PP_ALIGN.CENTER
    r0 = p0.add_run()
    r0.text = num
    r0.font.bold = True
    r0.font.size = Pt(38)
    r0.font.color.rgb = color

    p1 = tf.add_paragraph()
    p1.alignment = PP_ALIGN.CENTER
    p1.space_before = Pt(2)
    r1 = p1.add_run()
    r1.text = label
    r1.font.bold = True
    r1.font.size = Pt(15)
    r1.font.color.rgb = C_WHITE

    if sub:
        p2 = tf.add_paragraph()
        p2.alignment = PP_ALIGN.CENTER
        p2.space_before = Pt(2)
        r2 = p2.add_run()
        r2.text = sub
        r2.font.size = Pt(11)
        r2.font.color.rgb = C_MUTED

# ==========================================
# SLIDE 1: HOOK & VISION (VISUAL)
# ==========================================
s1 = create_slide()
# Real Photo on Right
if os.path.exists(IMG_HERO):
    try:
        s1.shapes.add_picture(IMG_HERO, Inches(6.8), Inches(1.1), width=Inches(5.7))
    except Exception:
        pass

# Title on Left
tb = s1.shapes.add_textbox(Inches(0.8), Inches(1.0), Inches(5.8), Inches(4.0))
tf = tb.text_frame
tf.word_wrap = True

p0 = tf.paragraphs[0]
r0 = p0.add_run()
r0.text = "XonaDosh"
r0.font.bold = True
r0.font.size = Pt(56)
r0.font.color.rgb = C_EMERALD

p1 = tf.add_paragraph()
p1.space_before = Pt(4)
r1 = p1.add_run()
r1.text = "Talabalar uchun Uy va Xonadosh Ilovasi"
r1.font.bold = True
r1.font.size = Pt(22)
r1.font.color.rgb = C_WHITE

p2 = tf.add_paragraph()
p2.space_before = Pt(8)
r2 = p2.add_run()
r2.text = "1. Universitet yonidan uy topish (0% makler)\n" \
          "2. 95% mos xonadosh tanlash\n" \
          "3. Uydagi navbatchilik va bozorlikni boshqarish"
r2.font.size = Pt(16)
r2.font.color.rgb = C_MINT

# Investment Ask Banner
banner = s1.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(0.8), Inches(5.3), Inches(11.7), Inches(1.5))
banner.fill.solid()
banner.fill.fore_color.rgb = C_CARD_ALT
banner.line.color.rgb = C_EMERALD
banner.line.width = Pt(1.5)
tf_b = banner.text_frame
tf_b.margin_left = Inches(0.4)
tf_b.margin_top = Inches(0.2)

p_b0 = tf_b.paragraphs[0]
r_b0 = p_b0.add_run()
r_b0.text = "INVESTITSIYA SO'ROVI: $50,000 (10% ULUSH  ·  $500,000 BAHOLASH)"
r_b0.font.bold = True
r_b0.font.size = Pt(20)
r_b0.font.color.rgb = C_GOLD

p_b1 = tf_b.add_paragraph()
p_b1.space_before = Pt(4)
r_b1 = p_b1.add_run()
r_b1.text = "Loyiha holati: Relizga tayyor  •  iOS, Android, Web ishlab turibdi  •  honadosh.uz"
r_b1.font.size = Pt(13)
r_b1.font.color.rgb = C_MUTED

# ==========================================
# SLIDE 2: THE PROBLEM (REAL PHOTO + 3 CLEAR PAINS)
# ==========================================
s2 = create_slide()
add_header(s2, "BOZOR MUAMMOSI", "1.3 Million Talaba Har Yili Qanday Qiynaladi?", "Avgust-Sentyabr oylarida yuz minglab talabalar sarson bo'ladi")

if os.path.exists(IMG_PROBLEM):
    try:
        s2.shapes.add_picture(IMG_PROBLEM, Inches(0.8), Inches(1.9), width=Inches(5.2))
    except Exception:
        pass

add_card(s2, 6.3, 1.9, 6.2, 1.5, 
         title="1. Maklerlar 50% Pulni Olib Qo'yadi", 
         subtitle="Katta Xarajat & Firibgarlar",
         bullets=["• OTMgacha masofa noaniq  • Qidiruvga 10-15 kun ketadi"],
         accent=C_RED, highlight=True)

add_card(s2, 6.3, 3.6, 6.2, 1.5, 
         title="2. Noto'g'ri Xonadosh & Janjal", 
         subtitle="1-2 Oyda Urush Boshlanadi",
         bullets=["• Uyqu va tozalik to'g'ri kelmaydi  • Doimiy ko'chib yurish"],
         accent=C_GOLD, highlight=True)

add_card(s2, 6.3, 5.3, 6.2, 1.5, 
         title="3. Uydagi Tartibsizlik", 
         subtitle="Maishiy Boshbodoqlik",
         bullets=["• Navbatchilik yo'q  • Bozorlik va qarzlar janjali"],
         accent=C_RED, highlight=True)

# ==========================================
# SLIDE 3: THE SOLUTION (3 SIMPLE STEPS)
# ==========================================
s3 = create_slide()
add_header(s3, "BIZNING YECHIM", "XonaDosh Bilan 2 Kunda Hal Bo'ladi", "Sarsonlikdan — qulay va xotirjam talabalik hayotiga")

add_card(s3, 0.8, 1.9, 6.2, 1.5, 
         title="1. Topish (Marketplace)", 
         subtitle="0% Makler Komissiyasi",
         bullets=["• OTM yonidagi uylar xaritasi  • Piyoda va metro vaqti hisobi"],
         accent=C_EMERALD, highlight=True)

add_card(s3, 0.8, 3.6, 6.2, 1.5, 
         title="2. Moslash (Smart Matching)", 
         subtitle="95% Mos Xonadosh",
         bullets=["• Uyqu, tozalik, byudjet bo'yicha moslash  • 80% kamroq nizo"],
         accent=C_MINT, highlight=True)

add_card(s3, 0.8, 5.3, 6.2, 1.5, 
         title="3. Yashash (Coliving OS)", 
         subtitle="Uydagi Tinch Hayot",
         bullets=["• Navbatchilik jadvali  • 21 taom  • Bozorlik hisobi  • Split-bills"],
         accent=C_GOLD, highlight=True)

if os.path.exists(IMG_MATCH):
    try:
        s3.shapes.add_picture(IMG_MATCH, Inches(7.3), Inches(1.9), width=Inches(5.2))
    except Exception:
        pass

# ==========================================
# SLIDE 4: COMPETITOR ANALYSIS (UZBEKISTAN & CENTRAL ASIA)
# ==========================================
s4 = create_slide()
add_header(s4, "RAQOBAT VA MOAT", "Raqobatchilar Kim va Biz Nega Yutamiz?", "O'zbekiston va Markaziy Osiyo bozoridagi mutlaq ustunligimiz")

add_card(s4, 0.8, 1.9, 2.7, 4.9, 
         title="❌ OLX & Krisha.kz", 
         subtitle="Faqat E'lon",
         bullets=[
             "• Maklerlar to'lib ketgan",
             "• Xonadosh tanlash yo'q",
             "• Uydan keyin ilova o'chadi",
             "• Churn: 95%+"
         ],
         accent=C_RED)

add_card(s4, 3.8, 1.9, 2.7, 4.9, 
         title="❌ Telegram Guruhlar", 
         subtitle="Xaos & Firibgarlar",
         bullets=[
             "• Qidiruv va xarita yo'q",
             "• Spam va firibgarlik ko'p",
             "• Xonadosh xarakteri noma'lum",
             "• Xavfsizlik 0"
         ],
         accent=C_GOLD)

add_card(s4, 6.8, 1.9, 2.7, 4.9, 
         title="❌ UyBor & Maklerlar", 
         subtitle="Juda Qimmat",
         bullets=[
             "• 50% komissiya oladi",
             "• Talabalar byudjetiga to'g'ri kelmaydi",
             "• Kvartira egasi bilan aloqa yo'q"
         ],
         accent=C_RED)

add_card(s4, 9.8, 1.9, 2.7, 4.9, 
         title="🔥 XonaDosh", 
         subtitle="Yagona Ekotizim",
         bullets=[
             "• OTM yonidan 0% komissiya",
             "• 95% mos xonadosh testi",
             "• Uydan keyin HAR KUNI faol",
             "• $0 CAC (organik oqim)"
         ],
         accent=C_EMERALD, highlight=True)

# ==========================================
# SLIDE 5: RETENTION / COLIVING OS
# ==========================================
s5 = create_slide()
add_header(s5, "RETENTION CORE", "Uydan Keyin Nega Har Kuni Ochiladi?", "Talaba ilovani o'chirmaydi — kundalik turmushini boshqaradi")

if os.path.exists(IMG_KITCHEN):
    try:
        s5.shapes.add_picture(IMG_KITCHEN, Inches(0.8), Inches(1.9), width=Inches(5.2))
    except Exception:
        pass

add_card(s5, 6.3, 1.9, 6.2, 1.15, title="🧹 Navbatchilik Jadvali", subtitle="Idish va Tozalash", bullets=["• 7 kunga avtomatik navbat taqsimoti"], accent=C_EMERALD)
add_card(s5, 6.3, 3.2, 6.2, 1.15, title="🍲 21 Taom Sloti", subtitle="Nima Ovqat Pishiramiz?", bullets=["• Talabalar uchun arzon retseptlar"], accent=C_MINT)
add_card(s5, 6.3, 4.5, 6.2, 1.15, title="🛒 Bozorlik Hisobi", subtitle="Chorsu Narxlari", bullets=["• Kishi boshiga xarajat hisoblash"], accent=C_GOLD)
add_card(s5, 6.3, 5.8, 6.2, 1.15, title="💰 Qarzlar & Split-Bill", subtitle="Kim Kimdan Qarz?", bullets=["• Ijara va kommunal to'lovlarni teng bo'lish"], accent=C_EMERALD)

# ==========================================
# SLIDE 6: MARKET SIZE (3 GIANT NUMBERS)
# ==========================================
s6 = create_slide()
add_header(s6, "BOZOR IMKONIYATI", "Bozor Qanchalik Katta va Kafolatlangan?", "O'zbekistonda yoshlar soni har yili shiddat bilan ko'paymoqda")

add_stat(s6, 0.8, 2.0, 3.6, 2.4, "1,300,000+", "O'zbekistonda Talabalar", "OTMlar soni 200 tadan oshdi", C_MINT)
add_stat(s6, 4.8, 2.0, 3.6, 2.4, "70%+", "Ijarada Yashaydi", "Yotoqxona o'rni 25% ga ham yetmaydi", C_EMERALD)
add_stat(s6, 8.8, 2.0, 3.6, 2.4, "$120,000,000", "Yillik Ijara Bozori", "Talabalarning yillik turar-joy xarajatlari", C_GOLD)

add_card(s6, 0.8, 4.8, 11.6, 2.0,
         title="Xulosa: Har Yili Avgustda 300,000+ Yangi Talaba Uy Qidiradi",
         bullets=[
             "• Oliy ta'lim qamrovi 9% dan 42% ga chiqdi — talabalar shaharchalari to'lib ketgan.",
             "• Davlat ijara subsidiyasi beryapti, lekin platforma yo'q.",
             "• XonaDosh bu muammoni hal qiluvchi birinchi va yagona to'liq ekotizimdir."
         ],
         accent=C_EMERALD, highlight=True)

# ==========================================
# SLIDE 7: BUSINESS MODEL (HOW WE MAKE MONEY)
# ==========================================
s7 = create_slide()
add_header(s7, "BIZNES MODEL", "Platforma Qayerdan Pul Ishlaydi?", "Talabalar uchun asosiy xizmatlar bepul, daromad 4 ta oqimdan keladi")

add_card(s7, 0.8, 2.0, 2.7, 4.9, 
         title="1. E'lonni Ko'tarish", 
         subtitle="$1 - $2",
         bullets=["• E'lonni tepaga chiqarish", "• Shoshilinch belgisi", "• VIP xonadosh qidiruvi"],
         accent=C_EMERALD, highlight=True)

add_card(s7, 3.8, 2.0, 2.7, 4.9, 
         title="2. Uy Egalari Obunasi", 
         subtitle="$5 - $10 / oy",
         bullets=["• Tekshirilgan talabalar", "• 2 kunda ijarachi kafolati", "• Talaba Karmasini ko'rish"],
         accent=C_MINT, highlight=True)

add_card(s7, 6.8, 2.0, 2.7, 4.9, 
         title="3. Bozorlik Yetkazish", 
         subtitle="5% Komissiya",
         bullets=["• Uzum Tezkor / Korzinka", "• Savatdan affiliate ulush", "• Arzon mebel va texnika"],
         accent=C_GOLD, highlight=True)

add_card(s7, 9.8, 2.0, 2.7, 4.9, 
         title="4. Kvartira To'lovlari", 
         subtitle="1% Split To'lov",
         bullets=["• Payme va Click orqali", "• Ijara va kommunal to'lash", "• Katta pul aylanmasi"],
         accent=C_EMERALD, highlight=True)

# ==========================================
# SLIDE 8: THE ASK & TEAM (CONCISE ACTION)
# ==========================================
s8 = create_slide()
add_header(s8, "INVESTITSIYA VA JAMOA", "Investitsiya Taklifi: $50,000 (10% Ulush)", "$500,000 Post-Money Baholash  ·  12-15 Oylik Runway")

# 3 Buckets on Left
add_card(s8, 0.8, 2.0, 5.6, 2.3, 
         title="Mablag'lar Qayerga Sarflanadi?",
         bullets=[
             "🚀 45% ($22,500) — Marketing (OTM elchilari va Avgust blitz)",
             "💻 30% ($15,000) — In-app chat, to'lovlar va server",
             "👥 25% ($12,500) — Jamoa va kutilmagan zaxira fondi"
         ],
         accent=C_GOLD, highlight=True)

# Team on Right
add_card(s8, 6.8, 2.0, 5.6, 2.3, 
         title="Asosiy Jamoa (Tajriba)",
         bullets=[
             "👑 Quvondiq Kenjaboyev — Founder & CEO (Mahsulot yetakchisi)",
             "💻 Bekmurod Ahmadov — Backend Lead (Workly, Mohirdev)",
             "📱 Shaxriyor Xuroyberdiyev — Mobile Lead (Uztelecom)"
         ],
         accent=C_MINT, highlight=True)

# Action Box at Bottom
action_box = s8.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(0.8), Inches(4.6), Inches(11.6), Inches(2.2))
action_box.fill.solid()
action_box.fill.fore_color.rgb = C_CARD_ALT
action_box.line.color.rgb = C_EMERALD
action_box.line.width = Pt(2)
tf_act = action_box.text_frame
tf_act.margin_left = Inches(0.4)
tf_act.margin_top = Inches(0.2)

p_act0 = tf_act.paragraphs[0]
r_act0 = p_act0.add_run()
r_act0.text = "Keling, Talabalar Kelajagini Birga Quraylik!"
r_act0.font.bold = True
r_act0.font.size = Pt(24)
r_act0.font.color.rgb = C_WHITE

p_act1 = tf_act.add_paragraph()
p_act1.space_before = Pt(6)
r_act1 = p_act1.add_run()
r_act1.text = "💬 Telegram orqali bog'lanish: @quvondiq  •  ✉️ info@honadosh.uz\n" \
              "🌐 Veb-sayt: honadosh.uz  •  Web Ilova: honadosh.uz/app/ (Demo: xdshot5122 / ShotTest123!)"
r_act1.font.size = Pt(15)
r_act1.font.color.rgb = C_MINT

# Save presentations
output_dist = os.path.join(DIST_DIR, 'XonaDosh_Startup_Pitch_Deck.pptx')
output_pitch = os.path.join(PITCH_WEB_DIR, 'XonaDosh_Startup_Pitch_Deck.pptx')

prs.save(output_dist)
prs.save(output_pitch)

print(f"SUCCESS: Super-simple 8-slide Pitch deck saved to:\n1) {output_dist}\n2) {output_pitch}")
