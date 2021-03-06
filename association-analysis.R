# ************************************************
# -- 연관어 분석(단어와 단어 사이 연관성 분석)
#    시각화 : 연관어 네트워크 시각화, 근접중심성 시각화
# ************************************************

# -------------------------------
# -- 한글 처리를 위한 패키지 설치
# -------------------------------
#install.packages("rJava")
#Sys.setenv(JAVA_HOME='C:\\Program Files\\Java\\jre1.8.0_112')
library(rJava)                                                 # 아래와 같은 Error 발생 시 Sys.setenv()함수로 java 경로 지정

#install.packages("KoNLP")
library(KoNLP)                                                       # rJava 라이브러리가 필요함

# ------------------------------
# -- 1. 텍스트 파일 가져오기
# ------------------------------

#marketing = file("C:\\RProject\\Rwork\\Part-II\\marketing.txt", encoding="UTF-8")
marketing2 = readLines("marketing.txt",encoding="UTF-8")                                    # 줄 단위 데이터 생성
# incomplete final line found on - Error 발생 시 UTF-8 인코딩 방식으로 재 저장
head(marketing2)

# ------------------------------
# -- 2. 줄 단위 단어 추출
# ------------------------------

# -- Map()함수 이용 줄 단위 단어 추출 : Map(f, ...) -> base)
?Map()
lword = Map(extractNoun, marketing2)
length(lword)                                                        # [1] 472
lword = unique(lword)                                                # 중복제거1(전체 대상)
length(lword)                                                        # [1] 353(19개 제거)

lword = sapply(lword, unique)                                        # 중복제거2(줄 단위 대상)
length(lword)                                                        # [1] 352(1개 제거)
str(lword)                                                           # List of 353
lword                                                                # 추출 단어 확인

# ------------------------------
# -- 3. 전처리
# ------------------------------

#       is.hangul()  : KoNLP 패키지 제공
#       Filter(f, x) : base
#       nchar()      : base -> 문자 수 반환

# -- 1) 길이가 2~4 사이의 단어 필터링 함수 정의
filter1 = function(x){
  nchar(x) <= 4 && nchar(x) >= 2 && is.hangul(x)
}

# -- 2) Filter(f,x) -> filter1() 함수를 적용하여 x 벡터 단위 필터링
filter2 = function(x){
  Filter(filter1, x)
}

# -- 3) 줄 단어 대상 필터링
lword = sapply(lword, filter2)

lword                                                                # 추출 단어 확인(길이 1개 단어 삭제됨)

# ------------------------------
# -- 4. 트랜잭션 생성 : 연관분석을 위해서 단어를 트랜잭션으로 변환
# ------------------------------

# -- arules 패키지 설치
install.packages("arules")
library(arules)

# -- arules 패키지 제공 기능
#    Adult,Groceries 데이터 셋
#    as(),apriori(),inspect(),labels(),crossTable()

wordtran = as(lword, "transactions")                                 # lword에 중복데이터가 있으면 error발생
wordtran

wordtable = crossTable(wordtran)                                     # 교차표 작성
wordtable

# ------------------------------
# -- 5. 단어 간 연관규칙 산출
# ------------------------------

# 트랜잭션 데이터를 대상으로 지지도와 신뢰도를 적용하여 연관규칙 생성
# 형식) apriori(data, parameter = NULL, appearance = NULL, control = NULL)
#       data :  object of class transactions,
#       parameter : support 0.1, conﬁdence 0.8, and maxlen 10(연관단어 최대수)
tranrules = apriori(wordtran, parameter=list(supp=0.25, conf=0.8))
# 0.22 -> 84 rules, supp=0.25 -> 59 rules
# 지지도와 신뢰도를 높이면 발견되는 규칙의 수가 줄어든다.

inspect(tranrules)                                                   # 연관규칙 생성 결과(59개) 보기

# ------------------------------
# 6.연관어 시각화 - rulemat[c(34:63),] # 연관규칙 결과- {} 제거(1~33)
#-------------------------------

# -- (1) 연관단어 시각화를 위해서 데이터 구조 변경
rules = labels(tranrules, ruleSep=" ")
print(rules)
class(rules)                                                         # [1] "character"
rules = sapply(rules, strsplit, " ",  USE.NAMES=F)
rulemat = do.call("rbind", rules)                                    # sapply(), do.call() # base 패키지
rulemat

# -- (2) 연관어 시각화를 위한 igraph 패키지 설치
#install.packages("igraph") # graph.edgelist(), plot.igraph(), closeness() 함수 제공
library(igraph)  

# -- (3) edgelist보기 - 연관단어를 정점 형태의 목록 제공
ruleg = graph.edgelist(rulemat[c(12:54),], directed=F)               # [1,]~[11,] "{}" 제외
ruleg

# -- (4) edgelist 시각화
dev.new(width = 1000, height = 1000, unit = "px")
plot.igraph(ruleg, vertex.label=V(ruleg)$name,
            vertex.label.cex=1.2, vertex.label.color='black',
            vertex.size=20, vertex.color='green', vertex.frame.color='blue')

# 정점(타원) 레이블 속성
# vertex.label=레이블명,vertex.label.cex=레이블 크기, vertex.label.color=레이블색
# 정점(타원) 속성
# vertext.size= 정점 크기, vertex.color=정점 색, vertex.frame.color=정점 테두리 색

#
# -- 7.단어 근접중심성(closeness centrality) 파악
#
closen = closeness(ruleg)                                            # edgelist 대상 단어 근접중심성 생성
#closen = closen[c(2:8)]                                             # {} 항목제거
closen = closen[c(1:10)]                                             # 상위 1~10 단어 근접중심성 보기

plot(closen, col="red",xaxt="n", lty="solid", type="b", xlab="단어", ylab="closeness")
points(closen, pch=16, col="navy")
axis(1, seq(1, length(closen)), V(ruleg)$name[c(1:10)], cex=5)       # 중심성 : 노드(node)의 상대적 중요성을 나타내는 척도이다.
# plot, points(), axis() : graphics 패키지(기존 설치됨


