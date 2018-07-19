import nltk

# pop open the nltk downloader : downloads required nltk packages
# nltk.download()

'''
Tokenizing - 
    Given a character sequence and a defined document unit, tokenization is the task of chopping it up into pieces, called tokens , perhaps at the same time throwing away certain characters, such as punctuation
    Word tokenizing and sentence tokenizing - seperate by work vs. seperate by sentence
Corporas and Lexicons -
    Corpora - a body of text. Eg. a medical journal, presidential speeches
    Lexicon - words and their meanings - same words may have different meanings in diff. lexicons
    
    Eg. Investor dictionary vs. English dictionary
    Investor dictionary 'bull' - upward trending market
    English  dictionary 'bull' - animal
       
'''

from nltk.tokenize import sent_tokenize, word_tokenize

example_text = "What is Mr. Suns radius? Where did earth come from? Water is not blue."

# Note - nltk can recognize that the '.' after salutation is not end of sentence and hence does not seperate out the sentence in two halves
print(sent_tokenize(example_text))
print(word_tokenize(example_text))

'''
nltk can also perform part of speech tagging where it recognizes what part of speech a given token falls in

Unsupervised ML can be used to build custom tokenizers besides the basic ones discussed in above code

nltk trainers can be used to make nltk work in any language

'''
