using Distributed

mutable struct LinkedList
    data::String
    next::Union{LinkedList, Nothing}
end

const square_size = 9
const filler = join(fill("*", square_size))

function algorithm(starter, d)
    row = square_size
    curr_words = [LinkedList(filler, nothing) for i=1:square_size]
    curr_words[row].data = starter

    while row > 1
        if @time squareisvalid(curr_words, row, d)
            row -= 1
            key = ""
            rows_being_used = @view curr_words[row + 1:end] 
            for ele in rows_being_used
                key *= ele.data[row]
            end
            curr_words[row] = d[key]
        elseif isnothing(curr_words[row].next)
            while isnothing(curr_words[row].next) && row < square_size
                # curr_words[row] = LinkedList(filler, nothing)
                row += 1
            end
            if row == square_size
                # println("not found")
                return
            end
            curr_words[row] = curr_words[row].next 
        else
            curr_words[row] = curr_words[row].next
        end
    end
    # print found match
    for node in curr_words
        println(node.data)
    end
    println()
end

function squareisvalid(curr_words, curr_row, d)
    for col = 1:square_size
        key = ""
        for row = curr_row:square_size
            key *= curr_words[row].data[col]
        end
        if !haskey(d, key)
            return false
        end
    end

    return true
end

function main()
    # read into buf
    f = open("words_alpha.txt", "r")
    buf = map(chomp, filter((x) -> length(x) == square_size, readlines(f)))
    close(f)

    # set up dict
    d = Dict{String, LinkedList}()
    for word in buf
        for i = 1:square_size
            key = word[i:end]
            if haskey(d, key)
                d[key] = LinkedList(word, d[key])
            else
                d[key] = LinkedList(word, nothing)
            end
        end
    end

    println("commencing work with: ", Threads.nthreads(), " threads")
    Threads.@threads for i in 1:length(buf)
        algorithm(buf[i], d)
    end
end
