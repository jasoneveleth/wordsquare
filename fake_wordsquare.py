import getch
import pickle

# file = open("sorted_words_dict.pickle", "rb")
# buckets = pickle.load(file)
# list_of_all_words = buckets[6]
square_size = 6

list_of_all_words = []
file = open("words_alpha.txt", "r")
line = file.readline()
while line:
    if len(line) == square_size + 1:
        list_of_all_words.append(line)
    line = file.readline()
file.close()

num_total_words = len(list_of_all_words)
print("done reading")



validation_set = set()
for word in list_of_all_words:
    for i in range(square_size):
        validation_set.add(word[i:-1])

def algorithm():
    likelywords = [list_of_all_words, list_of_all_words, list_of_all_words, list_of_all_words, list_of_all_words, list_of_all_words]
    # likelywords = [0]*square_size # 2D array, all words sorted for each row
    # for i in range(len(likelywords):
    #     likelywords[i] = sort_by_prob(row, likelywords)

    curr_row = square_size
    square_so_far = ['']*square_size # 2D array of chars, or 1D array of strings
    curr_words = [-1]*square_size # INDEXES
    
    print_counter = 0
    while curr_row >= 0:
        # --------------------
        print_counter += 1
        if print_counter % 10000000 == 0:
            # print(f"curr_row = {curr_row}")
            print(f"curr_words = {curr_words}")
            for i in square_so_far:
                str = ''
                if i == '':
                    str += '* '*square_size + '  '
                else:
                    for j in i:
                        str += j + ' '
                print(f"|{str[:-3]}|")
        # --------------------
        if there_exists_solution(square_so_far, curr_row):
            curr_row -= 1
            curr_words[curr_row] += 1
            square_so_far[curr_row] = likelywords[curr_row][curr_words[curr_row]]
        else:
            while curr_words[curr_row] == num_total_words - 1:
                square_so_far[curr_row] = ''
                curr_words[curr_row] = 0
                curr_row += 1

            curr_words[curr_row] += 1
            square_so_far[curr_row] = likelywords[curr_row][curr_words[curr_row]]
    return square_so_far

def sort_by_prob(row, likelywords):
    likeliness = [0]*len(likelywords)
    for i in range(len(likelywords)):
        pass # something
    return list

def there_exists_solution(square_so_far, curr_row):
    if curr_row == square_size:
        return True
    for curr_col in range(square_size):
        suffix = ''
        for i in range(curr_row, square_size):
            suffix += square_so_far[i][curr_col]
        if not (suffix in validation_set):
            return False
    # for curr_col in range(square_size):
    #     should_continue = 0
    #     for word in list_of_all_words:
    #         word_passes = True
    #         for i in range(curr_row, square_size):
    #             if word[i] != square_so_far[i][curr_col]:
    #                 word_passes = False
    #         if word_passes:
    #             should_continue = 1
    #     if should_continue == 0:
    #         return False
    return True

# def there_exists_solution(square_so_far, curr_row):
#     str = ""
#     for i in square_so_far:
#         if i == '':
#             str += '* * *\n'
#             continue
#         for j in i:
#             str += j + ' '
#         str += '\n'
#     print(str[:-1])
#     user_input = getch.getch()
#     if user_input == '1':
#         print("got True")
#         return True
#     else:
#         print("got False")
#         return False

square = algorithm()

str = ''
for i in square:
    if i == '':
        str += '* * *\n'
        continue
    for j in i:
        str += j + ' '
    str += '\n'
print(str[:-1])
