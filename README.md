# EC524: Heart-disease classification 心臟疾病預測分類

### Groups
* 王柏仁, 108753204
* 林祐丞, 108753209
* 李鈺祥, 108753206
* 唐英哲, 108753207
* 蕭郁君, 109753203

### Goal
* 若鐵達尼存活預測是
    * 初入資料科學、Kaggle競賽的熱門入門題
    * 初入特徵工程，了解其過程及特徵選取
    * 瞭解資料科學的運作過程
* 那此次的心臟病分類預測競賽就是
    * 正式實作資料科學的流程
    * 較深入進行特徵工程，用各種假設檢定、熵來了解特徵之間對答案及模型的重要性
    * 遇到實務上的問題並嘗試著解決

### Demo 

* 資料前處理

    ```R
    Rscript code/data_processing_1.R
    Rscript code/data_processing_2.R
    ```
* 模型訓練及驗證：

    ```R
    Rscript code/model_glm.R
    Rscript code/finalXGB.R --train [csv file path] --test [csv file path] --predict [output result csv path]
    ```
* 視覺化：

    ```R
    Rscript code/plot_performance.R
    ```

## Folder organization and its related information

### docs
* Your presentation, [1082_datascience_FP_3.pptx](docs/1082_datascience_FP_3.pptx), by **Jun. 15**

### data

* Link: https://www.kaggle.com/c/ec524-heart-disease/data

* 根據官方原始文件：
    1. age
    2. sex
    3. chest_pain: type of chest pain
        - Value of 1: typical angina
        - Value of 2: atypical angina
        - Value of 3: non-anginal pain
        - Value of 4: asymptomatic
    4. resting_bp: resting blood pressure
    5. cholestoral: serum cholestoral in mg/dl
    6. high_sugar: an indicator for whether fasting blood sugar > 120 mg/dl (1 = true; 0 = false)
    7. ecg: resting electrocardiographic results
        - Value of 0: normal
        - Value of 1: having ST-T wave abnormality (T wave inversions and/or ST elevation or depression of > 0.05 mV)
        - Value of 2: showing probable or definite left ventricular hypertrophy by Estes' criteria
    8. max_rate: maximum heart rate achieved
    9. exercise_angina: exercise induced angina (1 = yes; 0 = no)
    10. st_depression: ST depression induced by exercise relative to rest
    11. slope: the slope of the peak exercise ST segment
        - Value of 1: upsloping
        - Value of 2: flat
        - Value of 3: downsloping
    12. vessels: number of major vessels (0–3) colored by flourosopy
    13. thalium_scan: thalium heart scan
        - Value of 3: normal
        - Value of 6: fixed defect
        - Value of 7: reversable defect

* 資料前處理：
    - Outlier：（> 第三四分位 + 0.5*IQR； < 第一四分位 - 0.5*IQR ）：
        - 將個欄位 outlier 的 index 記錄起來，找將共同的 id 的資料並移除
        - 其他 outlier 則用最大值或最小值補齊，避免訓練時讓模型訓練錯誤
    - 類別變數與答案之間的關係處理：
        - 變數間的重要性與相關性
            - Chi Square 假設檢定：
            - 當 p value 小於 alpha（0.05），則拒絕 H0，也就是兩變數之間相關；反之則接受 H0，即兩變數獨立
        - Mutual Information：
            - 利用相互資訊熵，來觀察變數對於答案 Label 的重要程度
    - NA 處理：
        - 利用 median 補 NA 值或是以 decision tree,  拿沒有 NA 的 column 項來預測遺失值
    - 重新標籤：
        - 利用設定區間或是 Kmeans 針對資料本身特性進行標籤化
        - One hot encoding
        - 針對資料分布，re-label 原本的特徵：slope label
        - 針對 thalium_scan 特徵處理：(3, 6, 7) ->(1,2,3)
    - 正規化（Normalize）

### code

* 對於此次比賽我們使用模型有：XGBoost / Logistic Regression

* 針對模型訓練，我們採取以下方式：
    - 利用 xgb.importance 找出較重要的特徵並訓練模型
    - 相對於 Null Model，我們有針對飽和模型進行 Baseline 模型之前的訓練，並利用 T Test 找到較重要的特徵後，進行該特徵的強化與處理
    - 用 try and error 的精神，根據不同且較重要的特徵選取（結合），進行訓練，挑選較好的模型
    - 根據 proposed-final 模型，我們設不同的 seed 來訓練模型

* 我們使用 K-Fold Cross Validation 來進行模型驗證

### results

* 我們使用了 Accuracy, Test Error 來進行衡量，以找到最佳之模型

* 針對不同的資料處理及標籤設定，會有不同訓練結果。加上我們採取不同標籤的結合來訓練模型，以及改變 seed 也會影響結果。綜合以上，我們最後且最佳模型有很大進步

* 對於此次比賽的結果， 我們認為資料的特徵工程及選擇較為困難，因為不知道何者是最重要且必要的特徵。此外，訓練時的抽樣方法也需多加要研究

## Reference
* Paper：
    - XGBoost：https://arxiv.org/pdf/1603.02754.pdf
* 資料處理：
    - https://www.datacamp.com/community/tutorials/contingency-tables-r
    - https://www.pluralsight.com/guides/cleaning-up-data-from-outliers
    - https://www.gastonsanchez.com/r4strings/formatting.html
    - https://www.guru99.com/r-data-frames.html
* 套件引用：
    - https://cran.r-project.org/web/packages/hash/hash.pdf
    - https://stackoverflow.com/questions/23765996/get-all-keys-from-ruby-hash
    - https://www.rdocumentation.org/packages/tibble/versions/1.4.2/topics/add_column
    - https://stackoverflow.com/questions/45741498/add-column-in-tibble-with-variable-column-name
    - https://statmath.wu.ac.at/projects/vcd/
    - https://rdrr.io/cran/infotheo/man/mutinformation.html
    - https://cran.r-project.org/web/packages/infotheo/infotheo.pdf
    - https://www.rdocumentation.org/packages/stringr
    - https://stringr.tidyverse.org/reference/str_detect.html
    - https://www.rdocumentation.org/packages/vcd/
* 其他資料：
    - Age interval（年齡區間劃分）
        - 出自《[老年性生理學和老年的性生活](http://www.wunan.com.tw/www2/download/preview/1JBK.PDF)》一書
    - Blood pressure interval（血壓區間劃分）
    - Cholestoral interval（總膽固醇區間劃分）
        - [啟新診所](https://www.ch.com.tw/index.aspx?sv=ch_fitness&chapter=ACC000007)
        - [馬偕醫院](http://www.mmh.org.tw/taitam/endoc/dia-edu-b04.htm)




