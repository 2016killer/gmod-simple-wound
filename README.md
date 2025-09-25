### 1. 许可证说明  
本项目包含多个开源代码来源，各部分遵循其原始许可证：  
1. 部分代码来自 `https://github.com/meetric1/gwater2`，遵循 **GPLv3 许可证**（完整文本见 `LICENSE-GPLv3`）。  
2. 部分代码来自 [ValveSoftware/source-sdk-2013](https://github.com/ValveSoftware/source-sdk-2013)，遵循 **SOURCE 1 SDK LICENSE**（完整文本及第三方组件声明见 `thirdparty/source-sdk-2013/LICENSE` 和 `thirdparty/source-sdk-2013/thirdpartylegalnotices.txt`）。  
3. 子模块代码来自 [danielga/garrysmod_common](https://github.com/danielga/garrysmod_common)，遵循 **MIT 许可证**（完整文本见 `thirdparty/garrysmod_common/LICENSE`）。  

使用时请遵守各许可证的具体条款。


### 2. 本项目原创及修改部分的版权声明
本项目中：  
- 所有原创代码（非来自上述开源项目的部分）；  
- 对上述开源代码的修改、适配及整合部分；  

版权归 [白狼、Zack、2016killer] 所有（Copyright © 2025）。  


### 3. 授权说明
本项目的所有原创及修改内容，均需遵循上述各开源代码的原始许可证条款进行分发和使用（如GPLv3要求的开源衍生作品、SOURCE 1 SDK LICENSE的非商业限制等）。  

使用本项目即表示你同意遵守所有适用许可证的完整条款。


# 目的
关于血腥渲染效果，L4D2的方案是使用着色器对模型剔除后添加伤口模型，这对于个人开发者来说成本太高，
所以我创建了本项目，我对C++、hlsl的理解只有三天的水平，所以代码仅供参考。

![图](/img/img5.jpg)
![图](/img/img6.jpg)
![图](/img/img7.jpg)
![图](/img/img8.jpg)

# 内容

## 1.椭球剔除着色 (Valve L4D2的方案)
详见 https://alex.vlachos.com/graphics/Vlachos-GDC10-Left4Dead2Wounds.pdf

顶点级剔除
![图](/img/img1.jpg)

传入局部变换矩阵给顶点着色器，计算顶点距离(用于剔除判断)和投影坐标(用于采样血液纹理)
在像素着色器中传入两个参数用于控制剔除大小与血液纹理范围



## 2.射线剔除着色 (白狼的方案)
像素级剔除 (依赖纹理资源, 开销可能较大)
![图](/img/img2.jpg)
![图](/img/img3.jpg)

传入局部变换矩阵给顶点着色器，计算局部坐标（用于深度纹理采样）和投影坐标(用于采样血液纹理)
深度纹理是提前烘焙好的，必须是偶数层，这是因为剔除依赖于遮挡次数的奇偶性，此项目中使用一张纹理的RGBA通道存储4张深度纹理。

### 球体深度纹理
![图](/img/img8.png)
### 正方体深度纹理
![图](/img/img9.png)
### 圆锥体深度纹理
![图](/img/img10.png)

## 3.椭球变形着色 (Zack的方案)
![图](/img/img4.jpg)
类似于椭球剔除，只是将在椭球内的顶点投影到椭球面上，而在椭球外的顶点保持不变，变形部分与未变形部分采用不同纹理。

## 4.反向漫反射着色 (2016killer的补充，并不重要)
用于配合射线剔除着色渲染伤口内部, 只适用于不需要蒙皮的模型