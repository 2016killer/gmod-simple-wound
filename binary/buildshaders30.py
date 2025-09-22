import os
import sys
import argparse
import shutil
import subprocess
import time
import json

RED = '\x1b[31m'
GREEN = '\x1b[32m'
YELLOW = '\x1b[33m'
BLUE = '\x1b[34m'
RESET = '\x1b[39m'

def Warn(*args):
    print(YELLOW, '=======Warning=======\n', *args, RESET)

def Success(*args):
    print(GREEN, '=======Success=======\n', *args, RESET)

def Error(*args):
    print(RED, '=======Error=======\n', *args, RESET)
    sys.exit(1)

def Info(*args):
    print(BLUE, '=======Info=======\n', *args, RESET)

def main():
    
    # ===================== 参数 =====================
    current_dir = os.path.dirname(os.path.abspath(__file__))
    bat_path = os.path.join(current_dir, 'buildgmodshaders.bat')
    shaders_dir = os.path.join(current_dir, 'src', 'shaders')
    hlsl_dir = os.path.join(shaders_dir, 'hlsl')
    inc_dir = os.path.join(shaders_dir, 'inc')
    vcs_dir = os.path.join(shaders_dir, 'vcs')
    
    # 优先使用--sdk-path, 其次是系统变量 SOURCE_SDK_2013_SP_STDSHADERS
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--sdk-path',
        type=str,
        required=False,
        help='Source SDK 2013 SP 的 stdshaders 目录路径（覆盖系统变量）'
    )

    args = parser.parse_args()
    
    sdk_path = args.sdk_path or os.getenv('SOURCE_SDK_2013_SP_STDSHADERS')

    if not sdk_path or not os.path.isdir(sdk_path):
        Error(
            'SDK路径未找到!\n'
            '使用以下任意一种方式指定\n'
            '1.使用参数--sdk-path=U:\\source-sdk-2013-singleplayer\\src\\materialsystem\\stdshaders\n'
            '2.设置环境变量 SOURCE_SDK_2013_SP_STDSHADERS\n'
        )

    # ===================== 拷贝hlsl_dir下的着色器到SDK=====================
    os.makedirs(hlsl_dir, exist_ok=True) 

    shaders = [
        file for file in os.listdir(hlsl_dir)
        if file.lower().endswith(('30.fxc', '30.hlsl'))
    ]


    for item in shaders:
        source_item = os.path.join(hlsl_dir, item)
        target_item = os.path.join(sdk_path, item)
        shutil.copy2(source_item, target_item)

    # ===================== 修改 stdshader 清单文件=====================
    # 只编译30 版本
    list_30_path = os.path.join(sdk_path, 'stdshader_dx9_30.txt')
    with open(list_30_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(shaders))


    # ===================== 开始编译=====================
    Info(
        '开始执行编译脚本\n'
        f'SDK:{sdk_path}\n'
        f'{len(shaders)}个\n',
        json.dumps(shaders, ensure_ascii=False, indent=2)
    )
  
    try:
        result = subprocess.run(
            bat_path,
            cwd=sdk_path,
            shell=True,  
            check=True,  
            capture_output=True,
            text=True,
            encoding='gbk'
        )
        
        print(result.stdout)
        if result.stderr:
            print(result.stderr)
    except subprocess.CalledProcessError as e:
        Error(e.stderr, f'返回码: {e.returncode}')
        sys.exit(1)


    # ===================== 拷贝编译产物到inc_dir/vcs_dir=====================
    time.sleep(1)
    os.makedirs(vcs_dir, exist_ok=True)
    os.makedirs(inc_dir, exist_ok=True)

    sdk_vcs_dir = os.path.join(sdk_path, 'shaders', 'fxc')
    sdk_inc_dir = os.path.join(sdk_path, 'include')
   
    count = 0
    for file in shaders:
        shadername = os.path.splitext(file)[0]

        sdk_vcs_result = os.path.join(sdk_vcs_dir, f'{shadername}.vcs')
        vcs_result = os.path.join(vcs_dir, f'{shadername}.vcs')

        sdk_inc_result = os.path.join(sdk_inc_dir, f'{shadername}.inc')
        inc_result = os.path.join(inc_dir, f'{shadername}.inc')

        if os.path.exists(sdk_vcs_result):
            shutil.copy2(
                sdk_vcs_result, 
                vcs_result
            )

            os.chmod(sdk_inc_result, 0o777)
            shutil.copy2(
                sdk_inc_result, 
                inc_result
            )

            count += 1
        else:
            Warn(f'{file} 编译失败')


    Success(
        f'编译完成\n'
        f'复制文件 {count} 个'
    )

    sys.exit(0)

if __name__ == '__main__':
    main()
