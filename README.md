# Project_Snake


This is my Snake game coded in assembly RISC-V. To start the game you need to:<br>
1)  Install Java on your computer. You can download it on [Oracle's official site](https://www.oracle.com/java/technologies/downloads/?er=221886) with .dmg extension for MacOs and .exe for Windows. After the installation you can run <pre> ```java -version``` </pre>
2)  Download the /ressources directory. Open the terminal and run the following command within this directory <pre> ```java -jar rars1_6.jar``` </pre><br>

After the window of RISC-V appears, open the Project_snake file from ressources directory by clicking File -> Open
<img width="361" alt="Screenshot 2024-11-03 at 19 34 57" src="https://github.com/user-attachments/assets/6af6eab4-a52a-42a8-b3a2-7aa7d858990d"><br>
In the Tools section, select Bitmap Display and Keyboard Display MIMO Simulator
<img width="504" alt="Screenshot 2024-11-03 at 19 52 03" src="https://github.com/user-attachments/assets/5f882f71-1e0e-4cdd-989d-237b643ee29e"><br>
After both windows were opened, setup the Bitmap disply with Unit Width/Height - 8, Display Width/Height - 256, Base address for display - 0x10008000 (gp)
Then in the left bottom corner of both windows click "Connect to program"
<img width="978" alt="Screenshot 2024-11-03 at 19 53 49" src="https://github.com/user-attachments/assets/de92d182-f729-4d8c-b66e-f6d4bb8a9d91"><br>
Once done, press the key to assemble the program and then the big green button to start the game

<img width="152" alt="Screenshot 2024-11-03 at 19 58 29" src="https://github.com/user-attachments/assets/afa7bba0-5d09-4624-ad8b-504db2a6d05e"><br>
This is the image you will see on the display, to move the snake (green pixel) to the food (random generated red pixel) use WASD keys for up, left, down and right movement. Make sure you type within the Keyboard section in MIMO Simulator to move the snake. The borders with the obstacles have the blue color, so if the snake goes into them the game is finished. You can also skip the game by pressing x
<img width="398" alt="Screenshot 2024-11-03 at 20 01 58" src="https://github.com/user-attachments/assets/811bec29-c543-4dea-b3e3-c01343ca8667">
