from multiprocessing import Pool

square_size = 7
print_counter = 0
jump = 1000
thr_count = 8

class Node:
    def __init__(self, string, next):
        self.str = string
        self.next = next

class List:
    def __init__(self, head, tail):
        self.head = head
        self.tail = tail

def add(linkedlist, data):
    node = Node(data, None)
    linkedlist.tail.next = node
    linkedlist.tail = node

def myprint(curr_words):
    global print_counter 
    print_counter += 1
    if print_counter % jump == 0:
        for node in curr_words:
            str = ''
            for letter in node.data:
                str += letter + ' '
            print(f"|{str[:-1]}|")
        print()

def algorithm(start_end_words):
    # essetially doing an iteration to set up
    row = square_size - 1
    curr_words = [Node('*'*square_size, None)]*square_size
    suffix = ''
    for i in range(row + 1, square_size):
        suffix += curr_words[i].data[row]
    curr_words[row] = penis[suffix].head
    while curr_words[row].data != start_end_words[0]:
        curr_words[row] = curr_words[row].next

    while (row >= 0) and (curr_words[square_size - 1] != start_end_words[1]):
        # myprint(curr_words)
        if valid_square(curr_words, row):
            row -= 1
            suffix = ''
            for i in range(row + 1, square_size):
                suffix += curr_words[i].data[row]

            curr_words[row] = penis[suffix].head
        elif curr_words[row].next != None:
            curr_words[row] = curr_words[row].next
        else:
            while curr_words[row].next == None:
                curr_words[row] = None
                row += 1
            curr_words[row] = curr_words[row].next
    return curr_words

def valid_square(curr_words, curr_row):
    for col in range(square_size):
        suffix = ''
        for row in range(curr_row, square_size):
            suffix += curr_words[row].data[col]

        if not (suffix in penis):
            return False
    return True

def sort_by_prob(row, likelywords):
    likeliness = [0]*len(likelywords)
    for i in range(len(likelywords)):
        pass # something
    return list


if __name__ == "__main__":
    penis = {}
    total_word_count = 0

    file = open("words_alpha.txt", "r")
    line = file.readline()[:-1]
    while line:
        if len(line) == square_size:
            total_word_count += 1
            for i in range(square_size+1): # +1 to add line to '' key
                key = line[i:]
                if key in penis:
                    add(penis[key], line)
                else:
                    node = Node(line, None)
                    penis[key] = List(node, node)
        line = file.readline()[:-1]
    file.close()

    node_list = []

    input = []
    node = penis[''].head
    chunk = total_word_count//thr_count
    for _ in range(thr_count):
        input.append(node)
        for i in range(chunk - 1): # -1 makes room for extra next
            node = node.next
        input.append(node)
        node = node.next

    with Pool(processes=thr_count) as pool:
        print("starting...")
        node_list = pool.map(algorithm, input, 2)

    for node in node_list:
        str = ''
        for letter in node.data:
            str += letter + ' '
        print(f"|{str[:-1]}|")

