import string
import datetime
import time
from collections import Counter

import nltk
from nltk.corpus import stopwords

from logger import log

from sklearn.pipeline import Pipeline, FeatureUnion
from sklearn.base import BaseEstimator, TransformerMixin
from sklearn.feature_extraction import DictVectorizer
from sklearn.feature_extraction.text import TfidfTransformer
from sklearn.feature_selection import SelectKBest, chi2
from sklearn.preprocessing import MaxAbsScaler
from sklearn.linear_model import SGDClassifier
from sklearn.model_selection import KFold
from sklearn.metrics import classification_report, precision_recall_fscore_support

KFOLD = 5
NUMBER_OF_FEATURES = 'all'

def identity(arg):
    """
    Simple identity function works as a passthrough.
    """
    return arg


def build_model(messages, labels, print_feature_names=False):
    """
    Build function that builds a single model.
    :param messages: List of tokenised messages
    :type messages: list or any iterable
    :param labels: List of human annotated labels corresponding to messages
    :type labels: list or any iterable
    :param classifier: Classifier which must implement fit (see sklearn
                       documentation on the final estimator of a Pipeline)
    :type classifier: any
    :return: Fitted model of the entire classification pipeline
    :rtype: Pipeline
    """
    feature_extractors = [
        ('word frequency', NGramFrequencyExtractor(ngram_size=1)),
        ('2gram frequency', NGramFrequencyExtractor(ngram_size=2)),
        ('3gram frequency', NGramFrequencyExtractor(ngram_size=3)),
    ]

    model = Pipeline([
        ('preprocessor', NLTKPreprocessor()),
        ('feature extractors', FeatureUnion(feature_extractors)),
        ('tfidf transformer', TfidfTransformer()),
        ('scaler', MaxAbsScaler()),
        ('feature selector', SelectKBest(chi2, k=NUMBER_OF_FEATURES)),
        ('classifier', SGDClassifier(max_iter=1000, tol=1e-3))
    ])

    model.fit(messages, labels)

    if print_feature_names:
        all_feature_names = model.named_steps['feature extractors'].get_feature_names()
        feature_mask = model.named_steps['feature selector'].get_support()

        extracted_feature_names = []
        for feature, mask_bool in zip(all_feature_names, feature_mask):
            if mask_bool:
                extracted_feature_names.append(feature)
        print(extracted_feature_names)

    return model

def build_and_evaluate(messages, labels):
    """
    Splits data into train/test, then builds and evaluates a classifier.
    Classifier must implement fit (see sklearn documentation on the final
    estimator of a Pipeline)

    NB: Building & evaluating model in 09/2017 on dataset of 27000 raw text
    files took approx 450 seconds.
    :param messages: List of tokenised messages
    :type messages: list or any iterable
    :param labels: List of human annotated labels corresponding to messages
    :type labels: list or any iterable
    :param classifier: Classifier which must implement fit (see sklearn
                       documentation on the final estimator of a Pipeline)
    :type classifier: any
    :return: Fitted model of the entire classification pipeline
    :rtype: Pipeline
    """
    model_scores = []
    best_model_index = -1
    best_model = None
    best_fscore = 0

    cross_validation = KFold(n_splits=KFOLD, shuffle=True)
    for i, (train_indices, test_indices) in enumerate(cross_validation.split(messages)):
        start_time = datetime.datetime.now()
        model_score = {}

        messages_train = [messages[i] for i in train_indices]
        labels_train = [labels[i] for i in train_indices]
        messages_test = [messages[i] for i in test_indices]
        labels_test = [labels[i] for i in test_indices]

        # log("Building model...")
        model = build_model(messages_train, labels_train)
        # log("Model built")

        predicted_labels = model.predict(messages_test)
        # log("Classification report:\n" + classification_report(labels_test, predicted_labels))

        seen_labels = set(labels)
        # print (seen_labels)

        scores = compute_model_score(labels_test, predicted_labels)

        # if related_model_score["fscore"] > best_fscore:
            # best_model = model
            # best_model_index = i

        # model_score["related"] = related_model_score
        # model_score["unrelated"] = unrelated_model_score
        # scores["best-model"] = False
        # scores["time-taken-ms"] = (datetime.datetime.now() - start_time).microseconds / 1000

        model_scores.append(scores)

    # model_scores[best_model_index]["best-model"] = True

    return model, model_scores


def compute_model_score(correct_labels, predicted_labels):
    """
    Computes precision, recall, fscore and number of occurrences in correct_labels for each label
    ("related" and "unrelated")
    :param correct_labels: Ground truth (correct) target values.
    :type correct_labels: 1d array-like, or label indicator array / sparse matrix
    :param predicted_labels: Estimated targets as returned by a classifier.
    :type predicted_labels: 1d array-like, or label indicator array / sparse matrix
    :return: related and unrelated scores in dicts
    :rtype: tuple(dict[str, float])
    """

    seen_labels = list(set(correct_labels))

    precision, recall, fscore, support = precision_recall_fscore_support(correct_labels, predicted_labels, labels=seen_labels)

    scores = {}
    for i in range(0, len(seen_labels)):
        scores[seen_labels[i]] = {
            "precision": precision[i],
            "recall": recall[i],
            "fscore": fscore[i],
            "support": float(support[i])
        }

    return scores


def check_token(token, stopwords_set, punctuation_set):
    """
    Checks whether token is valid, i.e. not a stopword or punctuation.
    :param token: Input token to be checked
    :type token: str
    :param stopwords_set: List of stopwords (most common words in a language with
                           little to no semantic significance)
    :type stopwords_set: set(str) or list(str)
    :param punctuation_set: List of punctuation characters
    :type punctuation_set: set(str) or list(str)
    :return: True if valid, False if stopword or punctuation
    :rtype: bool
    """
    punctuation = True
    for character in token:
        if character not in punctuation_set:
            punctuation = False
            break

    if punctuation:
        return False

    if token in stopwords_set:
        return False

    return True

class NLTKPreprocessor(BaseEstimator, TransformerMixin):
    """
    Transforms input data by using NLTK tokenization, lemmatization, and
    other normalization and filtering techniques.
    """
    stopwords_set = set(stopwords.words('english'))
    punctuation_set = set(string.punctuation)

    should_ignore_case = True
    should_strip_token = True

    def __init__(self, stopwords_set=None, punctuation_set=None, should_ignore_case=True, should_strip_token=True):
        """
        Instantiates the preprocessor, which make load corpora, models, or do
        other time-intenstive NLTK data loading.
        :param stopwords_set: List of stopwords (most common words in a language with
                               little to no semantic significance)
        :type stopwords_set: set(str) or list(str)
        :param punctuation_set: List of punctuation characters
        :type punctuation_set: set(str) or list(str)
        :param should_ignore_case: Whether to ignore case or not
        :type should_ignore_case: bool
        :param strip: Whether to strip away whitespaces, underscores, and asterisks
        :type strip: bool
        """
        if stopwords_set:
            self.stopwords_set = set(stopwords_set)

        if punctuation_set:
            self.punctuation_set = set(punctuation_set)

        self.should_ignore_case = should_ignore_case
        self.should_strip_token = should_strip_token

    def fit(self, X, y=None):
        """
        Fit simply returns self, no other information is needed.
        """
        return self

    def inverse_transform(self, X):
        """
        No inverse transformation
        """
        return X

    def transform(self, messages):
        """
        Actually runs the preprocessing on each document.
        :param messages: List of untokenised messages
        :type messages: list(str) or any iterable
        :return: List of tokenised messages
        :rtype: list(list(str))
        """
        tokenised_messages = []

        for message in messages:
            processed_tokens = []

            for token in self.tokenize(message):
                processed_token = token

                if self.should_ignore_case:
                    processed_token = processed_token.lower()

                if self.should_strip_token:
                    processed_token = self.strip_token(processed_token)

                processed_tokens.append(processed_token)

            tokenised_messages.append(processed_tokens)

        return tokenised_messages

    def tokenize(self, message):
        """
        Breaks a message into a list of tokens
        :param message: message to be tokenised in a single string
        :type message: str
        :return: List of tokens in the message as separate strings
        :rtype: list(str)
        """
        tokenised_message = []

        # Break the document into sentences
        for sentence in nltk.sent_tokenize(message):
            # Break the sentence into tokens
            for token in nltk.wordpunct_tokenize(sentence):
                tokenised_message.append(token)

        return tokenised_message

    def strip_token(self, token):
        """
        Removes whitespaces, underscores and asterisks from the beginning and end of a string
        :param token: string to be stripped
        :type token: str
        :return: processed string
        :rtype: str
        """
        processed_token = token

        processed_token = processed_token.strip()
        processed_token = processed_token.strip('_')
        processed_token = processed_token.strip('*')

        return processed_token


class NGramFrequencyExtractor(BaseEstimator, TransformerMixin):
    """
    Transformer object turning messages into frequency feature vectors counting ngrams up to specified maximum.
    Sci-kit learn documentation on creating estimators: http://scikit-learn.org/dev/developers/contributing.html#rolling-your-own-estimator
    """
    ngram_size = -1
    vectorizer = None

    def __init__(self, ngram_size=1):
        self.ngram_size = ngram_size
        self.vectorizer = DictVectorizer()

    def fit(self, X, y):
        """
        Determines the list of tokens and ngrams to be used
        :param X: List of tokenised messages
        :type X: list(list(str))
        """
        frequency_dicts = []
        for message in X:
            tuple_ngrams = nltk.ngrams(message, self.ngram_size)
            string_ngrams = []
            for ngram in tuple_ngrams:
                string_ngrams.append(",".join(ngram))
            frequency_dicts.append(Counter(string_ngrams))

        self.vectorizer.fit(frequency_dicts)
        return self

    def transform(self, X, y=None):
        """
        Transforms tokenised messages into frequency vectors
        :return: frequency vectors
        :rtype: numpy array of shape [n_samples, n_features]
        """
        frequency_dicts = []
        for message in X:
            tuple_ngrams = nltk.ngrams(message, self.ngram_size)
            string_ngrams = []
            for ngram in tuple_ngrams:
                string_ngrams.append(",".join(ngram))
            frequency_dicts.append(Counter(string_ngrams))

        return self.vectorizer.transform(frequency_dicts)

    def fit_transform(self, X, y=None, **fit_params):
        """
        Fit to data then transform it
        :return: frequency vectors
        :rtype: numpy array of shape [n_samples, n_features]
        """
        frequency_dicts = []
        for message in X:
            tuple_ngrams = nltk.ngrams(message, self.ngram_size)
            string_ngrams = []
            for ngram in tuple_ngrams:
                string_ngrams.append(",".join(ngram))
            frequency_dicts.append(Counter(string_ngrams))

        return self.vectorizer.fit_transform(frequency_dicts)

    def get_feature_names(self):
        return self.vectorizer.get_feature_names()

class NormalisedNGramFrequencyExtractor(BaseEstimator, TransformerMixin):
    """
    Transformer object turning messages into frequency feature vectors counting ngrams up to specified maximum.
    Sci-kit learn documentation on creating estimators: http://scikit-learn.org/dev/developers/contributing.html#rolling-your-own-estimator
    """
    maximum_ngram_size = -1
    vectorizer = None
    canonical_forms = None

    def __init__(self, ngram_size, canonical_forms):
        self.ngram_size = ngram_size
        self.vectorizer = DictVectorizer()
        self.canonical_forms = canonical_forms

    def fit(self, X, y):
        """
        Determines the list of tokens and ngrams to be used
        :param X: List of tokenised messages
        :type X: list(list(str))
        """
        frequency_dicts = []
        for message in X:
            normalised_message = self.normalise_message(message)
            tuple_ngrams = nltk.ngrams(normalised_message, self.ngram_size)

            string_ngrams = []
            for ngram in tuple_ngrams:
                string_ngrams.append(",".join(ngram))

            frequency_dicts.append(Counter(string_ngrams))

        self.vectorizer.fit(frequency_dicts)
        return self

    def transform(self, X, y=None):
        """
        Transforms tokenised messages into frequency vectors
        :return: frequency vectors
        :rtype: numpy array of shape [n_samples, n_features]
        """
        frequency_dicts = []
        for message in X:
            normalised_message = self.normalise_message(message)
            tuple_ngrams = nltk.ngrams(normalised_message, self.ngram_size)

            string_ngrams = []
            for ngram in tuple_ngrams:
                string_ngrams.append(",".join(ngram))

            frequency_dicts.append(Counter(string_ngrams))

        return self.vectorizer.transform(frequency_dicts)

    def fit_transform(self, X, y=None, **fit_params):
        """
        Fit to data then transform it
        :return: frequency vectors
        :rtype: numpy array of shape [n_samples, n_features]
        """
        frequency_dicts = []
        for message in X:
            normalised_message = self.normalise_message(message)
            tuple_ngrams = nltk.ngrams(normalised_message, self.ngram_size)

            string_ngrams = []
            for ngram in tuple_ngrams:
                string_ngrams.append(",".join(ngram))

            frequency_dicts.append(Counter(string_ngrams))

        return self.vectorizer.fit_transform(frequency_dicts)

    def get_feature_names(self):
        return self.vectorizer.get_feature_names()

    def normalise_message(self, message):
        normalised_message = []

        for word in message:
            if word.isnumeric():
                normalised_message.append("num" + str(len(word)))   # "num5" for 12345
            elif word in self.canonical_forms:
                normalised_message.append(self.canonical_forms[word])
            else:
                normalised_message.append(word)

        return normalised_message
