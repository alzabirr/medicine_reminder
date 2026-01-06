import sys

def check_balance(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    stack = []
    pairs = {')': '(', ']': '[', '}': '{'}
    lines = content.split('\n')
    
    for i, line in enumerate(lines):
        for j, char in enumerate(line):
            if char in '([{':
                stack.append((char, i+1, j+1))
            elif char in ')]}':
                if not stack:
                    print(f"Extra closing {char} at {i+1}:{j+1}")
                    return
                top, li, co = stack.pop()
                if pairs[char] != top:
                    print(f"Mismatched {char} at {i+1}:{j+1}, expected closer for {top} from {li}:{co}")
                    return
    
    if stack:
        for char, li, co in stack:
            print(f"Unclosed {char} from {li}:{co}")
    else:
        print("Balanced!")

if __name__ == "__main__":
    check_balance(sys.argv[1])
