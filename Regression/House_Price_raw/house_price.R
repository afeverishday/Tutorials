# house price

library(data.table)
library(dplyr)
train<-fread("Regression/House_Price_raw/train.csv", stringsAsFactors = F)
test<-fread("Regression/House_Price_raw/test.csv", stringsAsFactors = F)

# EDA
dim(train)  # data ���� Ȯ��
dim(test)
str(train) # ���� Ȯ��
str(test)
head(train)
head(test)
tail(train)
tail(test)
     
test_labels <- test$Id  # �Ŀ� submission�� ���� test�� id�� ���Ϳ� �ΰ�, ������ �����Ѵ�.
test$Id <- NULL
train$Id <- NULL

test$SalePrice <- NA     # rbind ���� �۾����� ���� ���� ���߱� ���� SalePrice ���� ����
all <- rbind(train, test)


dim(all)
str(all) # ���� Ȯ��
head(all)


library(ggplot2)
library(scales)
options(scipen = 10) # ��� ����ǥ��
ggplot(data = all[!is.na(all$SalePrice),], aes(x = SalePrice)) +
  geom_histogram(fill = 'blue', binwidth = 10000) +
  scale_x_continuous( labels = comma) 
#0~80������ 10�� ������ x�� ǥ��(������ ,) breaks = seq(0, 800000, by = 10000),

all<-as.data.frame(all)
summary(all)



numericVars <- which(sapply(all, is.numeric)) # index ���� numeric ���� ����
numericVarNames <- names(numericVars) #�̸� �����Ͽ� ���� ����
cat('There are', length(numericVars), 'numeric variables')

all_numVar <- all[, numericVars]
cor_numVar <- cor(all_numVar, use='pairwise.complete.obs') # �� numeric ������ ��� ���

# SalePrice���� ��� ��� ������������ ����
cor_sorted <- as.matrix(sort(cor_numVar[, 'SalePrice'], decreasing = TRUE))
# ��� ����� ū �������� ����
CorHigh <- names(which(apply(cor_sorted, 1, function(x) abs(x) > 0.5)))
cor_numVar <- cor_numVar[CorHigh, CorHigh]

library(corrplot)
corrplot.mixed(cor_numVar, 
               tl.col = 'black',   # ������ ����
               tl.pos = 'lt',      # ������ ���� ǥ��
               number.cex = .7)    # matrix�� ������ text ũ��


ggplot(data = all[!is.na(all$SalePrice),], aes(x = factor(OverallQual), y = SalePrice)) +
  geom_boxplot(col = 'blue') + labs(x = 'Overall Quality') +
  scale_y_continuous( labels = comma) 
#0~80������ 10�������� y�� ǥ��(������ ,)

library(ggrepel)
ggplot(data = all[!is.na(all$SalePrice),], aes(x = GrLivArea , y = SalePrice)) +
  geom_point(col = 'blue') + 
  geom_smooth(method = 'lm', se = FALSE, color = 'black', aes(group = 1)) +
  scale_y_continuous( labels = comma) +
  geom_text_repel(aes(label = ifelse(all$GrLivArea[!is.na(all$SalePrice)] > 4500, #price 7500�̻� �ؽ�Ʈ ǥ��
                                     rownames(all), '')))

# �̻�ġ�� �ش��ϴ� �������� ���ݰ� ǰ�� Ȯ��
out_rowname<-which(all$GrLivArea[!is.na(all$SalePrice)] > 4500)
all[out_rowname, c('SalePrice', 'GrLivArea', 'OverallQual')]

#����ġ Ȯ��
NAcol <- which(colSums(is.na(all)) > 0)  # ��� ����ġ ���� ����
sort(colSums(sapply(all[NAcol], is.na)), decreasing = TRUE) #����ġ ���� ���� �������� ����

cat('There are', length(NAcol), 'columns with  missing values')

# Pool ����
table(all$PoolQC)

all$PoolQC<-ifelse(is.na(all$PoolQC),'None',all$PoolQC)
Qualities <- c('None' = 0, 'Po' = 1, 'Fa' = 2, 'TA' = 3, 'Gd' = 4, 'Ex' = 5)
library(plyr)
all$PoolQC <- as.integer(revalue(all$PoolQC, Qualities))

table(all$PoolArea)
all %>% filter(PoolQC==0 & PoolArea>0) %>% select(PoolArea, PoolQC, OverallQual)
all$PoolQC<- ifelse(all$PoolQC==0 & all$PoolArea>0, all$OverallQual, all$PoolQC)


# miscellanuous ����� 
table(all$MiscFeature)
all$MiscFeature<-ifelse(is.na(all$MiscFeature),'None',all$MiscFeature)

all$MiscFeature <- as.factor(all$MiscFeature)
ggplot(all[complete.cases(all$SalePrice),] , aes(x = MiscFeature, y = SalePrice)) +
  geom_bar(stat = 'summary', fun.y = 'median', fill = 'blue') +
  scale_y_continuous(breaks = seq(0, 800000, by = 100000), labels = comma) +
  geom_label(stat = 'count', aes(label = ..count.., y = ..count..)) #���� �׷��� count �󺧸�

# Alley ����,�ޱ�
table(all$Alley)
all$Alley<-ifelse(is.na(all$Alley),'None',all$Alley)
all$Alley<- as.factor(all$Alley)

ggplot(all[!is.na(all$SalePrice),], aes(x = Alley, y = SalePrice)) + 
  geom_bar(stat = 'summary', fun.y = 'median', fill = 'blue') +
  scale_y_continuous(breaks = seq(0, 200000, by = 50000), labels = comma)

# Fence
table(all$Fence)
all$Fence <- ifelse(is.na(all$Fence),'None', all$Fence)

all[!is.na(all$SalePrice),] %>% 
  group_by(Fence) %>%  #Fence �׷���
  summarise(median = median(SalePrice), counts = n()) #Fence������ price ������, ���� Ȯ��
# => no fence is best

all$Fence <- as.factor(all$Fence)

# Fireplace quality
table(all$Fireplaces)
sum(table(all$Fireplaces))
table(all$FireplaceQu)
all$FireplaceQu <- ifelse(is.na(all$FireplaceQu),'None',all$FireplaceQu)
#FireplaceQu ����ġ�� ���� fireplaces ������ 0�� ���� ��ġ�Ѵ�.
all$FireplaceQu<-revalue(all$FireplaceQu, Qualities) %>% as.integer()

# Lot variables
# LotFrontage: Linear feet of street connected to property
# LotShape: General shape of property
# LotConfig: Lot configuration
table(all$LotFrontage)
sum(table(all$LotFrontage))

ggplot(all[!is.na(all$LotFrontage),], 
       aes(x = as.factor(Neighborhood), y = LotFrontage)) +
  geom_bar(stat = 'summary', fun.y = 'median', fill = 'blue') + 
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) # Text 45�� ����, ���̴� 1�� ����

for (i in 1:nrow(all)) {
  if(is.na(all$LotFrontage[i])){
    all$LotFrontage[i] <- as.integer(median(all$LotFrontage[all$Neighborhood==all$Neighborhood[i]],
                                            na.rm = TRUE))
  }
}

table(all$LotShape)
sum(table(all$LotShape))
all$LotShape <- as.integer(revalue(all$LotShape, c('IR3' = 0, 'IR2' = 1, 'IR1' = 2, 'Reg' = 3)))


table(all$LotConfig)
sum(table(all$LotConfig))
ggplot(all[!is.na(all$SalePrice),], aes(x = as.factor(LotConfig), y = SalePrice)) +
  geom_bar(stat = 'summary', fun.y = 'median', fill = 'blue') +
  scale_y_continuous(breaks = seq(0, 800000, by = 100000), labels = comma) +
  geom_label(stat = 'count', aes(label = ..count.., y = ..count..))

all$LotConfig <- as.factor(all$LotConfig)

#  Garage ����
table(all$GarageYrBlt)
sum(table(all$GarageYrBlt))
all$GarageYrBlt<- ifelse(is.na(all$GarageYrBlt), all$YearBuilt, all$GarageYrBlt)


table(all$GarageType)
sum(table(all$GarageType))

table(all$GarageFinish)
sum(table(all$GarageFinish))

table(all$GarageCond)
sum(table(all$GarageCond))

table(all$GarageQual)
sum(table(all$GarageQual))

#157���� ����ġ�� 159�� ����ġ�� ������ ������ ����ġ���� Ȯ���� ���ڴ�.
length(which(is.na(all$GarageType) & is.na(all$GarageFinish) & is.na(all$GarageCond) & is.na(all$GarageQual)))


library(knitr)
#������ 2���� ����ġ�� ã�ƺ��ڴ�.
kable(all[!is.na(all$GarageType) & is.na(all$GarageFinish), 
          c('GarageCars', 'GarageArea', 'GarageType', 'GarageCond', 'GarageQual', 'GarageFinish')])

# �ֺ� ������ ����ġ ��ü
all$GarageCond[2127] <- names(sort(-table(all$GarageCond)))[1]
all$GarageQual[2127] <- names(sort(-table(all$GarageQual)))[1]
all$GarageFinish[2127] <- names(sort(-table(all$GarageFinish)))[1]

# ��ü �� �� Ȯ��
kable(all[2127, c('GarageYrBlt', 'GarageCars', 'GarageArea', 'GarageType', 'GarageCond', 'GarageQual', 'GarageFinish')])

# 2577 house�� ���� �Ҵ�
all$GarageCars[2577] <- 0
all$GarageArea[2577] <- 0
all$GarageType[2577] <- 'None'

# ������ ������ 4 ������ ����ġ�� ��� 158������ Ȯ���غ��ڴ�.
length(which(is.na(all$GarageType) & is.na(all$GarageFinish) & is.na(all$GarageCond) & is.na(all$GarageQual)))


all$GarageType[is.na(all$GarageType)] <- 'No Garage'
all$GarageType <- as.factor(all$GarageType)
table(all$GarageType)

all$GarageFinish[is.na(all$GarageFinish)] <- 'None'
Finish <- c('None' = 0, 'Unf' = 1, 'RFn' = 2, 'Fin' = 3) #������ ��ġ������ ��ȯ

all$GarageFinish <- as.integer(revalue(all$GarageFinish, Finish))
table(all$GarageFinish)

all$GarageQual[is.na(all$GarageQual)] <- 'None'
all$GarageQual <- as.integer(revalue(all$GarageQual, Qualities))
table(all$GarageQual)

all$GarageCond[is.na(all$GarageCond)] <- 'None'
all$GarageCond <- as.integer(revalue(all$GarageCond, Qualities))
table(all$GarageCond)


# Basement ���� ����
# 79���� ����ġ�� 80 �̻��� ����ġ�� ���� ������ ����ġ�� ���̴��� Ȯ���ϰڴ�.
length(which(is.na(all$BsmtQual) & is.na(all$BsmtCond) & is.na(all$BsmtExposure) & 
               is.na(all$BsmtFinType1) & is.na(all$BsmtFinType2)))

# �߰� ����ġ ã��: BsmtFinType1�� ����ġ�� �ƴ�����, �ٸ� 4�� �������� ����ġ�� ���
all[!is.na(all$BsmtFinType1) & (is.na(all$BsmtCond) | is.na(all$BsmtQual) | 
                                  is.na(all$BsmtExposure) | is.na(all$BsmtFinType2)), 
    c('BsmtQual', 'BsmtCond', 'BsmtExposure', 'BsmtFinType1', 'BsmtFinType2')]

# �ֺ󵵰����� ��ü�� �Ҵ�
all$BsmtFinType2[333] <- names(sort(-table(all$BsmtFinType2)))[1]
all$BsmtExposure[c(949, 1488, 2349)] <- names(sort(-table(all$BsmtExposure)))[1]
all$BsmtQual[c(2218,2219)] <- names(sort(-table(all$BsmtQual)))[1]
all$BsmtCond[c(2041, 2186, 2525)] <- names(sort(-table(all$BsmtCond)))[1]

all$BsmtQual[is.na(all$BsmtQual)] <- 'None'
all$BsmtQual <- as.integer(revalue(all$BsmtQual, Qualities))
table(all$BsmtQual)

all$BsmtCond[is.na(all$BsmtCond)] <- 'None'
all$BsmtCond <- as.integer(revalue(all$BsmtCond, Qualities))
table(all$BsmtCond)

all$BsmtExposure[is.na(all$BsmtExposure)] <- 'None'
Exposure <- c('None' = 0, 'No' = 1, 'Mn' = 2, 'Av' = 3, 'Gd' = 4)

all$BsmtExposure <- as.integer(revalue(all$BsmtExposure, Exposure))
table(all$BsmtExposure)

all$BsmtFinType1[is.na(all$BsmtFinType1)] <- 'None'
Fintype <- c('None' = 0, 'Unf' = 1, 'LwQ' = 2, 'Rec' = 3, 'BLQ' = 4, 'ALQ' = 5, 'GLQ' = 6)

all$BsmtFinType1 <- as.integer(revalue(all$BsmtFinType1, Fintype))
table(all$BsmtFinType1)

all$BsmtFinType2[is.na(all$BsmtFinType2)] <- 'None'
all$BsmtFinType2 <- as.integer(revalue(all$BsmtFinType2, Fintype))
table(all$BsmtFinType2)

# ��⿡ �����ߴ� ���Ͻ��� ������ 79ä�� �����Ͽ� ���� ����ġ�� Ȯ���غ���
all[(is.na(all$BsmtFullBath) | is.na(all$BsmtHalfBath) | is.na(all$BsmtFinSF1) | 
       is.na(all$BsmtFinSF2) | is.na(all$BsmtUnfSF) | is.na(all$TotalBsmtSF)), 
    c('BsmtQual', 'BsmtFullBath', 'BsmtHalfBath', 'BsmtFinSF1', 'BsmtFinSF2', 'BsmtUnfSF', 'TotalBsmtSF')]

all$BsmtFullBath[is.na(all$BsmtFullBath)] <- 0
table(all$BsmtFullBath)

all$BsmtHalfBath[is.na(all$BsmtHalfBath)] <- 0
table(all$BsmtHalfBath)

all$BsmtFinSF1[is.na(all$BsmtFinSF1)] <- 0
all$BsmtFinSF2[is.na(all$BsmtFinSF2)] <- 0
all$BsmtUnfSF[is.na(all$BsmtUnfSF)] <- 0
all$TotalBsmtSF[is.na(all$TotalBsmtSF)] <- 0

#Masonry veneer type, and masonry veneer area 
# veneer area�� 23�� ����ġ�� veneer type�� 23�� ����ġ���� Ȯ���� ���ڴ�. 
length(which(is.na(all$MasVnrType) & is.na(all$MasVnrArea)))

# veneer type�� 1�� ����ġ�� ã�ƺ���.
all[is.na(all$MasVnrType) & !is.na(all$MasVnrArea), c('MasVnrType', 'MasVnrArea')]

#veneer type�� ����ġ�� �ֺ󵵰����� ��ü����
all$MasVnrType[2611] <- names(sort(-table(all$MasVnrType)))[2] #�ֺ󵵴� 'none'�̶� �ι�° �󵵷� �ߴ�.
all[2611, c('MasVnrType', 'MasVnrArea')]

all$MasVnrType[is.na(all$MasVnrType)] <- 'None'
all[!is.na(all$SalePrice),] %>%    #����ġ �ƴ� SalePrice ����
  group_by(MasVnrType) %>%         # MasVnrType ������ �׷���
  summarise(median = median(SalePrice), counts=n()) %>%  # SalePrice ������, ���� ���
  arrange(median)                  # ������ ������ �������� ����

Masonry <- c('None' = 0, 'BrkCmn' = 0, 'BrkFace' = 1, 'Stone' = 2)
all$MasVnrType <- as.integer(revalue(all$MasVnrType, Masonry))
table(all$MasVnrType)

all$MasVnrArea[is.na(all$MasVnrArea)] <- 0

#MSZoning: �뵵�� ���� �ĺ��� 
# �ֺ󵵰����� ����ġ ��ü
all$MSZoning[is.na(all$MSZoning)] <- names(sort(-table(all$MSZoning)))[1]
all$MSZoning <- as.factor(all$MSZoning)
table(all$MSZoning)

sum(table(all$MSZoning))

# Kitchen quality and number of Kitchens above grade
# �ֺ󵵰����� ����ġ ��ü
all$KitchenQual[is.na(all$KitchenQual)] <- 'TA' 
all$KitchenQual <- as.integer(revalue(all$KitchenQual, Qualities))
table(all$KitchenQual)
sum(table(all$KitchenQual))
table(all$KitchenAbvGr)
sum(table(all$KitchenAbvGr))

#Utilities: ����� �� �ִ� Utilities�� ����
table(all$Utilities)
kable(all[is.na(all$Utilities) | all$Utilities == "NoSeWa", 1:9])
all$Utilities <- NULL


# Functional: Ȩ ���
# �ֺ󵵰����� ����ġ ��ü
all$Functional[is.na(all$Functional)] <- names(sort(-table(all$Functional)))[1]
all$Functional <- as.integer(revalue(all$Functional, +
                                       c('Sal' = 0, 'Sev' = 1, 'Maj2' = 2, 'Maj1' = 3, 'Mod' = 4, 'Min2' = 5, 'Min1' = 6, 'Typ' = 7)))
table(all$Functional)
sum(table(all$Functional))

#�ǹ� ���� ����
# �ֺ󵵰����� ����ġ ��ü
all$Exterior1st[is.na(all$Exterior1st)] <- names(sort(-table(all$Exterior1st)))[1]
all$Exterior1st <- as.factor(all$Exterior1st)
table(all$Exterior1st)
sum(table(all$Exterior1st))

# �ֺ󵵰����� ����ġ ��ü
all$Exterior2nd[is.na(all$Exterior2nd)] <- names(sort(-table(all$Exterior2nd)))[1]
all$Exterior2nd <- as.factor(all$Exterior2nd)
table(all$Exterior2nd)
sum(table(all$Exterior2nd))

all$ExterQual <- as.integer(revalue(all$ExterQual, Qualities))
table(all$ExterQual)
sum(table(all$ExterQual))

all$ExterCond <- as.integer(revalue(all$ExterCond, Qualities))
table(all$ExterCond)
sum(table(all$ExterCond))

# Electrical: ���� �ý���
# �ֺ󵵰����� ����ġ ��ü
all$Electrical[is.na(all$Electrical)] <- names(sort(-table(all$Electrical)))[1]
all$Electrical <- as.factor(all$Electrical)
table(all$Electrical)

sum(table(all$Electrical))

#SaleType: �Ǹ� ���
# �ֺ󵵰����� ����ġ ��ü
all$SaleType[is.na(all$SaleType)] <- names(sort(-table(all$SaleType)))[1]
all$SaleType <- as.factor(all$SaleType)
table(all$SaleType)
sum(table(all$SaleType))
#SaleCondition: �Ǹ� ����
all$SaleCondition <- as.factor(all$SaleCondition)
table(all$SaleCondition)
sum(table(all$SaleCondition))



# ������ ����
Charcol <- names(all[,sapply(all, is.character)]) #������ ������ �����Ͽ� ����
cat('There are', length(Charcol), 'remaining columns with character values')

#Foundation: �ǹ� ����(���)�� ����
#�������� �ƴϱ⿡, factor������ ��ȯ�ϰڴ�.
all$Foundation <- as.factor(all$Foundation)
table(all$Foundation)
sum(table(all$Foundation))

#�������� �ƴϱ⿡, factor������ ��ȯ�ϰڴ�.
all$Heating <- as.factor(all$Heating)
table(all$Heating)
sum(table(all$Heating))

# Qualities ���ͷ� ���������� ��ȯ�Ѵ�.
all$HeatingQC <- as.integer(revalue(all$HeatingQC, Qualities))
table(all$HeatingQC)
sum(table(all$HeatingQC))

all$CentralAir <- as.integer(revalue(all$CentralAir, c('N' = 0, 'Y' = 1)))
table(all$CentralAir)
sum(table(all$CentralAir))

# RoofStyle: ������ ����
# �������� �ƴϱ⿡, factor������ ��ȯ�ϰڴ�.
all$RoofStyle <- as.factor(all$RoofStyle)
table(all$RoofStyle)
sum(table(all$RoofStyle))
#RoofMatl: ���� ���
# �������� �ƴϱ⿡, factor������ ��ȯ�ϰڴ�.
all$RoofMatl <- as.factor(all$RoofMatl)
table(all$RoofMatl)
sum(table(all$RoofMatl))

#  LandContour: ������ ��ź��
# �������� �ƴϱ⿡, factor������ ��ȯ�ϰڴ�.
all$LandContour <- as.factor(all$LandContour)
table(all$LandContour)
sum(table(all$LandContour))
#LandSlope: ������ ���(��Ż)
# ������ Ÿ��, ���������� ��ȯ�ϰڴ�.
all$LandSlope <- as.integer(revalue(all$LandSlope, c('Sev' = 0, 'Mod' = 1, 'Gtl' = 2)))
table(all$LandSlope)
sum(table(all$LandSlope))

#BldgType: �ְ��� ����
ggplot(all[!is.na(all$SalePrice),], aes(x=as.factor(BldgType), y = SalePrice)) +
  geom_bar(stat = 'summary', fun.y = 'median', fill = 'blue') +
  scale_y_continuous(breaks = seq(0, 800000, by = 100000), labels = comma) +
  geom_label(stat = 'count', aes(label = ..count.., y = ..count..))

# ������ ���ְ� �ƴϱ⿡, factor�� ��ȯ�Ѵ�.
all$BldgType <- as.factor(all$BldgType)
table(all$BldgType)
sum(table(all$BldgType))

# HouseStyle: �ְ��� Style
# ������ ���ְ� �ƴϱ⿡, factor�� ��ȯ�Ѵ�.
all$HouseStyle <- as.factor(all$HouseStyle)
table(all$HouseStyle)
sum(table(all$HouseStyle))

#������ �Ÿ�, �ٹ��� ������ ���� 3���� ����
# ������ ���ְ� �ƴϱ⿡, factor�� ��ȯ�Ѵ�.
all$Neighborhood <- as.factor(all$Neighborhood)
table(all$Neighborhood)
sum(table(all$Neighborhood))
# Condition1: �ٹ��� �پ��� ����
# ������ ���ְ� �ƴϱ⿡, factor�� ��ȯ�Ѵ�.
all$Condition1 <- as.factor(all$Condition1)
table(all$Condition1)
sum(table(all$Condition1))
#Condition2: �ٹ��� �پ��� ���� (2�� �̻�)
# ������ ���ְ� �ƴϱ⿡, factor�� ��ȯ�Ѵ�.
all$Condition2 <- as.factor(all$Condition2)
table(all$Condition2)
sum(table(all$Condition2))
#Street: ������ ���� ���� ����
# ������ ���ַ�, ���������� ��ȯ�ϰڴ�.
all$Street <- as.integer(revalue(all$Street, c('Grvl' = 0, 'Pave' = 1)))
table(all$Street)
sum(table(all$Street))
#PavedDrive: ���Է��� ����
#������ ���ַ�, ���������� ��ȯ�ϰڴ�.
all$PavedDrive <- as.integer(revalue(all$PavedDrive, c('N' = 0, 'P' = 1, 'Y' = 2)))
table(all$PavedDrive)
sum(table(all$PavedDrive))

#numeric variable
str(all$YrSold)
str(all$MoSold)
all$MoSold <- as.factor(all$MoSold)


ys <- ggplot(all[!is.na(all$SalePrice),], aes(x = as.factor(YrSold), y = SalePrice)) +
  geom_bar(stat = 'summary', fun.y = 'median', fill = 'blue') +
  scale_y_continuous(breaks = seq(0, 800000, by = 25000), labels = comma) +
  geom_label(stat = 'count', aes(label = ..count.., y = ..count..)) +
  coord_cartesian(ylim = c(0, 200000)) + #y�� 20������ ǥ�� ����
  geom_hline(yintercept = 163000, linetype='dashed', color = 'red') #SalePrice ������

ms <- ggplot(all[!is.na(all$SalePrice),], aes(x = MoSold, y = SalePrice)) + 
  geom_bar(stat = 'summary', fun.y = 'median', fill = 'blue') +
  scale_y_continuous(breaks = seq(0, 800000, by = 25000), labels = comma) + 
  geom_label(stat = 'count', aes(label = ..count.., y = ..count..)) + 
  coord_cartesian(ylim = c(0, 200000)) +
  geom_hline(yintercept = 163000, linetype = 'dashed', color = 'red') 

library(gridExtra)
grid.arrange(ys, ms, widths = c(1,2))


#MSSubClass: �Ǹſ� ������ �ְ� Ÿ��

str(all$MSSubClass)

all$MSSubClass <- as.factor(all$MSSubClass)

# �������� ���̱� ���� ���ڸ� ���ڷ� revalue
all$MSSubClass <- revalue(all$MSSubClass, c('20'='1 story 1946+', '30'='1 story 1945-', '40'='1 story unf attic', '45'='1,5 story unf', '50'='1,5 story fin', '60'='2 story 1946+', '70'='2 story 1945-', '75'='2,5 story all ages', '80'='split/multi level', '85'='split foyer', '90'='duplex all style/age', '120'='1 story PUD 1946+', '150'='1,5 story PUD all', '160'='2 story PUD 1946+', '180'='PUD multilevel', '190'='2 family conversion'))

str(all$MSSubClass)

numericVars <- which(sapply(all, is.numeric)) # index vector numeric variables
factorVars <- which(sapply(all, is.factor))   # index vector factor variables
cat('There are', length(numericVars), 'numeric variables, and', length(factorVars), 
    'categoric variables')

all_numVar <- all[, numericVars]
cor_numVar <- cor(all_numVar, use = 'pairwise.complete.obs') # ��� ��ġ�� ������ ��� ���

# SalePrice�� �������� ��� ��� �������� ����
cor_sorted <- as.matrix(sort(cor_numVar[, 'SalePrice'], decreasing = TRUE))
# 0.5���� ���� ��� ��� ��� ����
CorHigh <- names(which(apply(cor_sorted, 1, function(x) abs(x) > 0.5)))
cor_numVar <- cor_numVar[CorHigh, CorHigh]

corrplot.mixed(cor_numVar, 
               tl.col = 'black',  # ������ ����
               tl.pos = 'lt',     # ������ ���� ǥ��
               tl.cex = 0.7,      # ������ text ũ��
               cl.cex = 0.7,      # y�� ������ text ũ��
               number.cex = .7    # matrix�� ������ text ũ��
)

library(randomForest)
set.seed(2018) #�μ� '2018'�� �õ� ����
quick_RF <- randomForest(x = all[1:1460, -79], y = all$SalePrice[1:1460], ntree = 100, importance = TRUE)
imp_RF <- importance(quick_RF)
imp_DF <- data.frame(Variables = row.names(imp_RF), MSE = imp_RF[,1])
imp_DF <- imp_DF[order(imp_DF$MSE, decreasing = TRUE),]

ggplot(imp_DF[1:20,],
       aes(x = reorder(Variables, MSE), y = MSE, fill = MSE)) + # MSE���� ���� ������
  geom_bar(stat = 'identity') + 
  labs(x = 'Variables', y = '% increase MSE if variable is randomly permuted') + #x,y��� ����
  coord_flip() + #x, y�� ����
  theme(legend.position = 'none')


s1 <- ggplot(data = all, aes(x = GrLivArea)) +
  geom_density() + labs(x = 'Square feet living area')
s2 <- ggplot(data = all, aes(x = as.factor(TotRmsAbvGrd))) +
  geom_histogram(stat = 'count') + labs(x = 'Rooms above Ground')
s3 <- ggplot(all, aes(x = X1stFlrSF)) +
  geom_density() + labs(x = 'Square feet first floor')
s4 <- ggplot(all, aes(x = X2ndFlrSF)) + 
  geom_density() + labs(x = 'Square feet second floor')
s5 <- ggplot(all, aes(x = TotalBsmtSF)) +
  geom_density()+ labs(x = 'Square feet basement')
s6 <- ggplot(all[all$LotArea < 100000,], aes(x = LotArea)) + 
  geom_density() + labs(x = 'Square feet lot')
s7 <- ggplot(all, aes(x = LotFrontage)) +
  geom_density() + labs(x = 'Linear feet lot frontage')
s8 <- ggplot(all, aes(x = LowQualFinSF)) +
  geom_histogram() + labs(x = 'Low quality square feet 1st & 2nd')

layout <- matrix(c(1,2,5,3,4,8,6,7),4,2, byrow = TRUE) # 4�� 2�� ()���� ������ ����� matrix ����
multiplot(s1, s2, s3, s4, s5, s6, s7, s8, layout = layout)