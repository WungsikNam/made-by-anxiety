import os
import telebot
from google import genai

# ==========================================
# 텔레그램 봇 토큰 & Gemini API Key 설정
# ==========================================
TELEGRAM_TOKEN = "8571432046:AAGMaJlc3Gadd5_3vaWH4zrYONEiO_SpBBE"

# 구글 AI Studio (aistudio.google.com) 에서 무료 발급받은 API 키를 넣으세요!
GEMINI_API_KEY = "AIzaSyClTkHiVPi1R6ZboHFn-y0kQ7hUwI4deII" 

bot = telebot.TeleBot(TELEGRAM_TOKEN)

# 각 사용자별 대화 문맥(Context)을 기억하기 위한 딕셔너리
chat_sessions = {}

@bot.message_handler(commands=['start', 'help'])
def send_welcome(message):
    bot.reply_to(message, "안녕하세요! Antigravity(제미나이 기반) 텔레그램 봇입니다.\n저와 여기서 대화를 나누실 수 있습니다! 무엇이든 물어보세요.")

@bot.message_handler(func=lambda message: True)
def handle_message(message):
    user_id = message.from_user.id
    user_text = message.text
    
    if GEMINI_API_KEY == "여기에_Gemini_API_키를_입력하세요":
        bot.reply_to(message, "봇 관리자가 아직 Gemini API Key를 설정하지 않았습니다. `chat_bot.py` 소스 코드를 열어 키를 입력해주세요.")
        return

    bot.send_chat_action(user_id, 'typing')
    
    try:
        # 처음 대화하는 사용자면 새로운 제미나이 챗 세션 생성
        if user_id not in chat_sessions:
            client = genai.Client(api_key=GEMINI_API_KEY)
            chat_sessions[user_id] = client.chats.create(model="gemini-2.5-flash")
            
        # 대화 전송 및 응답 받기
        chat = chat_sessions[user_id]
        response = chat.send_message(user_text)
        
        bot.reply_to(message, response.text)
        
    except Exception as e:
        bot.reply_to(message, f"오류가 발생했습니다: {str(e)}")

if __name__ == "__main__":
    print("AI 텔레그램 대화형 봇 시작 중...")
    if GEMINI_API_KEY == "여기에_Gemini_API_키를_입력하세요":
        print("[경고] Gemini API Key가 입력되지 않았습니다! (aistudio.google.com 에서 발급 필요)")
        
    bot.polling(none_stop=True)
