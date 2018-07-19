'''

nltk can help in a preprocessing the corpus

Stop words - Words that are not required to be analyzed


'''

from nltk.corpus import stopwords
from nltk.tokenize import word_tokenize

example_sentence = "This is an example showing off stop word filtration."
stop_words = set(stopwords.words("english"))# use the stop words from english language pre-defined by nltk
# print(stop_words)

words = word_tokenize(example_sentence)
filtered_sentence = []

for w in words:
    if w not in stop_words:
        filtered_sentence.append(w)

filtered_sentecne = [w for w in words if not w in stop_words]
print(filtered_sentence)
