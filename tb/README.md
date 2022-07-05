# 使用说明

### 批处理
双击run.bat或run_zh.bat即可执行  
`run.bat` 具有最好的通用性和稳定性，但是只有英文交互界面  
`run_zh.bat` 采用中文的交互界面，但是cmd解释器可能会因为中文引发奇怪的错误  
输入`[单个字符]`并回车，即可执行对应项目  

### Makefile
在当前目录下的终端输入`make`，显示可执行项目  
在当前目录下的终端输入`make [单个字符]`，执行对应项目  

### 可执行的项目

| 编号 | 功能 |
|---|---|
|0 | 载入inst.txt并仿真|
|1 | 执行RISC-V ISA测试集|
|2 | bin文件转为inst.txt|
|3 | 载入bin文件并仿真|
|4 | 显示上一次的仿真波形|
|c | 清理缓存文件|