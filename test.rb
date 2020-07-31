mkdir -p test
echo -n -e "file1:\nhoge\nfuga" > test/file1.txt
echo -n -e "file2:\n123\n456\n789\n\n" > test/file2.txt
echo -n -e "file3:\nfoo\nbar\nbaz" > test/file3.txt

#ruby file_implant.rb -a test/file1.txt test/file2.txt test/file3.txt test/file.merged.txt
ruby file_implant.rb -a test/large_image.jpg test/file1.txt test/file2.txt test/file3.txt test/implanted.jpg

cat test/file.merged.txt

mkdir -p test/parsed
rm -f test/parsed/*

#ruby file_implant.rb -d test/file.merged.txt test/parsed
ruby file_implant.rb -d test/implanted.jpg test/parsed
ls test/parsed/*

