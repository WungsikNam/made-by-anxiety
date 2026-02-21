import os
import subprocess
import telebot
from google import genai

# ==========================================
# 텔레그램 봇 토큰 & Gemini API Key 설정
# ==========================================
TELEGRAM_TOKEN = "8571432046:AAGMaJlc3Gadd5_3vaWH4zrYONEiO_SpBBE"
GEMINI_API_KEY = "AIzaSyClTkHiVPi1R6ZboHFn-y0kQ7hUwI4deII" 

bot = telebot.TeleBot(TELEGRAM_TOKEN)

# 각 사용자별 대화 문맥 기록용
chat_sessions = {}

# 특정 사람만 명령어를 실행하게 제한 가능
ALLOWED_USERS = []

def is_allowed(message):
    if not ALLOWED_USERS:
        return True
    return message.from_user.id in ALLOWED_USERS

@bot.message_handler(commands=['start', 'help'])
def send_welcome(message):
    bot.reply_to(message, "안녕하세요! Antigravity 통합 봇입니다.\n\n"
                          "1. /cmd 명령어 : PC 터미널 실행 (예: /cmd dir)\n"
                          "2. 그 외 일반 메시지 : 제미나이 AI와 대화")

# 터미널 명령어 실행용 Handler
@bot.message_handler(commands=['cmd'])
def execute_command(message):
    if not is_allowed(message):
        bot.reply_to(message, "권한이 없습니다.")
        return

    # '/cmd ' 이후의 텍스트 추출
    command = message.text[len('/cmd '):].strip()
    if not command:
        bot.reply_to(message, "사용법: /cmd [실행할 터미널 명렁어]")
        return
        
    bot.reply_to(message, f"명령어 실행 중...\n> {command}")

    try:
        # Windows Powershell로명령어 실행
        result = subprocess.run(
            ["powershell", "-Command", command],
            capture_output=True,
            text=True,
            encoding='cp949', 
            timeout=30 
        )

        output = result.stdout if result.stdout else result.stderr
        if not output.strip():
            output = "(출력 내용 없음 - 실행 완료)"

        if len(output) > 4000:
            output = output[:4000] + "\n...(내용이 너무 길어 생략됨)"

        bot.reply_to(message, f"```text\n{output}\n```", parse_mode='MarkdownV2')

    except Exception as e:
        bot.reply_to(message, f"오류 발생:\n{str(e)}")

# 일반 메시지는 AI 대화로 처리
@bot.message_handler(func=lambda message: True)
def handle_ai_message(message):
    user_id = message.from_user.id
    user_text = message.text
    
    if GEMINI_API_KEY == "여기에_Gemini_API_키를_입력하세요":
        bot.reply_to(message, "Gemini API 키가 입력되지 않았습니다.")
        return

    bot.send_chat_action(user_id, 'typing')
    
    try:
        # 최초 대화시 세션과 클라이언트 생성 (클라이언트가 GC에 의해 닫히는 것 방지)
        if user_id not in chat_sessions:
            client = genai.Client(api_key=GEMINI_API_KEY)
            chat = client.chats.create(model="gemini-2.5-flash")
            chat_sessions[user_id] = {"client": client, "chat": chat}
            
        chat = chat_sessions[user_id]["chat"]
        response = chat.send_message(user_text)
        bot.reply_to(message, response.text)
        
    except Exception as e:
        bot.reply_to(message, f"AI 응답 오류: {str(e)}")

import sys
import traceback

# === 에러 보고용 대상 사용자 ID (여기에 봇 소유자 ID를 적으세요) ===
# 예: ERROR_REPORT_ID = 123456789 (숫자)
ERROR_REPORT_ID = None

def report_error_to_telegram(error_text):
    if ERROR_REPORT_ID:
        try:
            bot.send_message(ERROR_REPORT_ID, f"⚠️ **[시스템 오류 발생]** ⚠️\n```text\n{error_text}\n```", parse_mode='MarkdownV2')
        except Exception as e:
            print(f"에러 전송 실패: {e}")
    else:
        print("ERROR_REPORT_ID가 설정되지 않아 텔레그램으로 에러를 보낼 수 없습니다.")

# 전역 예외 처리기 (Uncaught Exceptions)
def global_exception_handler(exc_type, exc_value, exc_traceback):
    error_msg = "".join(traceback.format_exception(exc_type, exc_value, exc_traceback))
    print("치명적 오류 발생:\n", error_msg)
    
    # 길이가 너무 길면 자르기 (텔레그램 제한 4096자)
    if len(error_msg) > 3000:
        error_msg = error_msg[:3000] + "\n... (생략됨)"
        
    report_error_to_telegram(error_msg)
    sys.__excepthook__(exc_type, exc_value, exc_traceback)

sys.excepthook = global_exception_handler

if __name__ == "__main__":
    print("통합 텔레그램 봇(AI & Terminal & 에러 리포터)이 시작되었습니다...")
    try:
        bot.polling(none_stop=True)
    except Exception as e:
        error_msg = traceback.format_exc()
        if len(error_msg) > 3000:
            error_msg = error_msg[:3000] + "\n... (생략됨)"
        report_error_to_telegram(f"Polling Crash:\n{error_msg}")
