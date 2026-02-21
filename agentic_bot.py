import os
import sys
import telebot
import traceback
from langchain_core.messages import SystemMessage, HumanMessage
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain.tools import tool
from langgraph.prebuilt import create_react_agent

# ==========================================
# 텔레그램 봇 토큰 & Gemini API Key 설정
# ==========================================
TELEGRAM_TOKEN = "8571432046:AAGMaJlc3Gadd5_3vaWH4zrYONEiO_SpBBE"
GEMINI_API_KEY = "AIzaSyClTkHiVPi1R6ZboHFn-y0kQ7hUwI4deII"

os.environ["GOOGLE_API_KEY"] = GEMINI_API_KEY
bot = telebot.TeleBot(TELEGRAM_TOKEN)

# ==========================================
# LangChain Tools (에이전트에게 쥐어줄 무기)
# ==========================================

@tool
def read_file(file_path: str) -> str:
    """Read the content of a file located at file_path. Useful for inspecting code, logs, or text files."""
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
            return f"File content of {file_path}:\n```\n{content}\n```"
    except Exception as e:
        return f"Error reading file {file_path}: {e}"

@tool
def write_file(input_str: str) -> str:
    """Write or overwrite content to a file. 
    Input format should strictly be: 
    File_Path|Content
    Example: c:/temp/hello.txt|Hello World
    """
    try:
        file_path, content = input_str.split("|", 1)
        file_path = file_path.strip()
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(content)
        return f"Successfully wrote to {file_path}"
    except Exception as e:
        return f"Error writing file. Ensure format is 'Path|Content'. Error: {e}"

@tool
def run_terminal(command: str, cwd: str = None) -> str:
    """Execute a shell command on Windows PowerShell. 
    Useful for running git, python scripts, or inspecting directories.
    If you need Administrator privileges, prefix your command EXACTLY with 'ADMIN: '.
    
    Args:
        command: The PowerShell command to execute.
        cwd: The absolute path to the directory where the command should run. (e.g. "C:\\path\\to\\dir"). If omitted, runs in the current directory.
    """
    import subprocess
    import os
    try:
        kwargs = {
            "capture_output": True,
            "text": True,
            "encoding": "cp949",
            "timeout": 120,
            "env": os.environ.copy()
        }
        if cwd and os.path.exists(cwd):
            kwargs["cwd"] = cwd

        is_admin = command.startswith("ADMIN: ")
        if is_admin:
            command = command[7:].strip()
            
            # Use Start-Process with -Verb RunAs to trigger UAC and run elevated
            cwd_arg = f'-WorkingDirectory "{cwd}" ' if cwd and os.path.exists(cwd) else ""
            ps_command = f'Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command \\"{command}\\"" {cwd_arg}-Verb RunAs -Wait'
            
            result = subprocess.run(
                ["powershell", "-Command", ps_command],
                **kwargs
            )
            return "Administrator command requested. Check the host machine for a UAC prompt. If approved, it executed in a separate window."
            
        else:
            # Normal execution
            ps_prefix = '[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User"), "Process"); '
            result = subprocess.run(
                ["powershell", "-Command", ps_prefix + command],
                **kwargs
            )
            output = result.stdout if result.stdout else result.stderr
            output = output.strip()
            if not output:
                output = "(Command executed successfully with no output)"
            if len(output) > 2000:
                output = output[:2000] + "\n...(truncated)"
            return output
    except Exception as e:
        return f"Command execution failed: {str(e)}"

# Tools List
agent_tools = [read_file, write_file, run_terminal]

# ==========================================
# Agent Configuration
# ==========================================

# Initialize the Gemini Model wrapped for Langchain
llm = ChatGoogleGenerativeAI(
    model="gemini-2.5-flash",
    temperature=0, # Agentics prefer 0 for deterministic tool calling
)

SYSTEM_PROMPT = """You are a Senior Autonomous AI Software Engineer operating directly on the User's Windows environment via Telegram.

Your Capabilities & Mandate:
- You possess file operations (read/write) and PowerShell CLI access.
- You are fully autonomous. When the user asks you to implement a feature, find a bug, or execute a command, DO NOT ask for permission to explore. Just use your tools to complete the goal.
- You must perform highly abstract meta-tasks such as "Align with agents", "Develop a new widget", or "Fix the flutter build".
- **ADMINISTRATOR ACCESS**: You possess ability to run commands as Admin. If the user asks you to do something requiring Admin rights (like installing services, changing registry, or modifying system files), prefix your terminal command with `ADMIN: `. This will trigger a prompt on the user's screen.

Fault Tolerance & Self-Correction:
- IF a command (like `flutter`, `npm`, `python`) is not found, DO NOT immediately give up.
- INSTEAD, use PowerShell to proactively search for the executable using `Get-ChildItem -Path C:\ -Filter "flutter.bat" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1` or similar logic. Then run it using its absolute path.
- IF a script execution throws a stack trace, read the error carefully, fix the code using `write_file`, and run it again.
- NEVER say "I am just a bot" or "I cannot do abstract tasks". You are an expert engineer and you figure it out.

Operating Environment:
- IMPORTANT: You are running on Windows. Always use Windows/PowerShell syntax (e.g., `dir`, `mkdir`, `Get-Content`, `type`).
- Be quiet and efficient. Only report final, verified results.

Language Policy:
- CRITICAL: You MUST write ALL of your final responses to the user in KOREAN (한국어) ONLY. No exceptions.
"""

agent_executor = create_react_agent(llm, tools=agent_tools)

# ==========================================
# Telegram Handlers
# ==========================================

chat_histories = {}

@bot.message_handler(commands=['start', 'help'])
def send_welcome(message):
    bot.reply_to(message, "안녕하세요! Antigravity **Agentive(능동형)** 봇이 가동되었습니다.\n"
                          "이제 저에게 대충 '폴더 하나 만들어줘' 혹은 '파일 읽고 내용 바꿔줘' 라고 지시하면 "
                          "제가 알아서 터미널을 열고 코드를 조작해 작업을 완수합니다.")

@bot.message_handler(func=lambda message: True)
def handle_agent_request(message):
    user_id = message.from_user.id
    user_text = message.text
    
    bot.send_chat_action(user_id, 'typing')
    
    try:
        bot.reply_to(message, "Agent: 작업을 계획하고 실행 중입니다... 잠시만 기다려주세요.")
        
        # Initialize message history for user with the System Prompt
        if user_id not in chat_histories:
            chat_histories[user_id] = [SystemMessage(content=SYSTEM_PROMPT)]
            
        # Append latest user request
        chat_histories[user_id].append(HumanMessage(content=user_text))
        
        # Invoke agent with the full raw message list
        inputs = {"messages": chat_histories[user_id]}
        response = agent_executor.invoke(inputs)
        
        # Extract the final AI message content
        final_answer = response["messages"][-1].content
        if isinstance(final_answer, list):
            # 딕셔너리 리스트로 올 경우 텍스트만 추출
            text_parts = [item.get("text", "") for item in final_answer if isinstance(item, dict) and "text" in item]
            final_answer = "\n".join(text_parts).strip()
            if not final_answer:
                final_answer = str(response["messages"][-1].content)
        
        # Save AI reply to history
        chat_histories[user_id].append(response["messages"][-1])
        
        # Truncate history if too long, preserving the system prompt
        if len(chat_histories[user_id]) > 15:
            sys_msg = chat_histories[user_id][0]
            chat_histories[user_id] = [sys_msg] + chat_histories[user_id][-14:]
            
        bot.reply_to(message, final_answer)
        
    except Exception as e:
        error_msg = f"에이전트 실행 중 치명적 오류: {str(e)}"
        print(traceback.format_exc())
        bot.reply_to(message, error_msg)

if __name__ == "__main__":
    print("Agentic 텔레그램 봇(LangGraph V0/V1 호환+Gemini)이 시작되었습니다...")
    bot.polling(none_stop=True)
