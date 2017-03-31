# Logic_Desigh_Lab
final project of Logic Design Lab

## Topic
Elevator

## Design Concept
We try to imitate elevator with the FPGA board.  
The elevator would be equipped with the following function:  
1. Show which floors the elevator is going to arrive;
2. Show which floor the elevator is currently at, and it is going up or down;
3. Both keypad and push buttons could control where the elevator should arrive;
4. Show opening or closing door animation;
5. Dip selection could control the speed of the elevator;
6. The elevator would sing different songs when arriving different floor

## Block Diagram of sound related modules
![](demoGraph/blockDia.jpg)

## State Diagram of LCD display
![](demoGraph/stateDia.jpg)

## Demo photos
![](demoGraph/1.jpg)  
Now the elevator is on standby on the third floor.  
    
![](demoGraph/2.jpg)  
Press some buttons, and the corresponding led would light up.  
    
![](demoGraph/3.jpg)  
“U” means that the elevator is currently going up, and the door is full open on the screen.  
    
![](demoGraph/4.jpg)  
This picture shows that the elevator is heading the ground floor. “D” is for down.  
    
![](demoGraph/5.jpg)  
The door is closed when the elevator is moving.  
    
![](demoGraph/6.jpg)  
The elevator arrived at ground floor. Before receiving next task, it would on standby.