from dataclasses import dataclass
from typing import Type

square_size = 7
print_counter = 0
jump = 1000

@dataclass
class Node:
    data: str
    next: Type["Node"]

@dataclass
class List:
    head: Node
    tail: Node

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

def algorithm():
    row = square_size
    curr_words = [Node('*'*square_size, None)]*square_size

    while row >= 0:
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

    file = open("words_alpha.txt", "r")
    line = file.readline()[:-1]
    while line:
        if len(line) == square_size:
            for i in range(square_size+1): # +1 to add line to '' key
                key = line[i:]
                if key in penis:
                    add(penis[key], line)
                else:
                    node = Node(line, None)
                    penis[key] = List(node, node)
        line = file.readline()[:-1]
    file.close()

    print("starting...")

    node_list = algorithm()

    for node in node_list:
        str = ''
        for letter in node.data:
            str += letter + ' '
        print(f"|{str[:-1]}|")

