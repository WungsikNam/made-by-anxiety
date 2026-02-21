import os
import subprocess
import telebot # Requires: pip install pyTelegramBotAPI

# ==========================================
# 텔레그램 봇 토큰 입력
# BotFather(@BotFather)에게 받은 토큰을 여기에 넣으세요!
# ==========================================
TOKEN = "8571432046:AAGMaJlc3Gadd5_3vaWH4zrYONEiO_SpBBE"
bot = telebot.TeleBot(TOKEN)

# ==========================================
# 사용자 인증 (아무나 명령어를 실행하지 못하게 방지)
# 본인의 텔레그램 User ID 배열을 작성하세요. 
# getidsbot (@getidsbot) 등을 통해 자신의 ID를 확인할 수 있습니다.
# ==========================================
ALLOWED_USERS = [] # 예시: [123456789]

def is_allowed(message):
    if not ALLOWED_USERS:
        return True # 빈 배열이면 누구나 사용 가능 (테스트 단계에서만 사용)
    return message.from_user.id in ALLOWED_USERS

@bot.message_handler(commands=['start', 'help'])
def send_welcome(message):
    bot.reply_to(message, "안녕하세요! Antigravity 원격 제어 봇입니다.\n\n"
                          "메시지에 터미널 명령어(cmd or powershell)를 입력하면 결과를 전송해 드립니다.\n"
                          "예시: dir, ping 8.8.8.8, python --version")

@bot.message_handler(func=lambda message: True)
def execute_command(message):
    if not is_allowed(message):
        bot.reply_to(message, "권한이 없습니다. 관리자에게 문의하세요.")
        return

    command = message.text
    bot.reply_to(message, f"명령어 실행 중...\n> {command}")

    try:
        # 명령어 실행 (Windows 환경)
        result = subprocess.run(
            ["powershell", "-Command", command],
            capture_output=True,
            text=True,
            encoding='cp949', # 한글 깨짐 방지
            timeout=30 # 무한 루프 방지
        )

        output = result.stdout if result.stdout else result.stderr

        if not output.strip():
            output = "(출력 내용 없음 - 실행 완료)"

        # 텔레그램 메시지 길이 제한(4096자) 방어
        if len(output) > 4000:
            output = output[:4000] + "\n...(내용이 너무 길어 생략됨)"

        bot.reply_to(message, f"```text\n{output}\n```", parse_mode='MarkdownV2')

    except subprocess.TimeoutExpired:
        bot.reply_to(message, "명령어 실행 시간이 초과되었습니다 (30초 제한).")
    except Exception as e:
        bot.reply_to(message, f"오류 발생:\n{str(e)}")

if __name__ == "__main__":
    if TOKEN == "여기에_토큰을_입력하세요":
        print("에러: 봇 토큰을 먼저 스크립트에 기입해주세요!")
    else:
        print("Antigravity 원격 제어 봇이 시작되었습니다...")
        bot.polling(none_stop=True)
