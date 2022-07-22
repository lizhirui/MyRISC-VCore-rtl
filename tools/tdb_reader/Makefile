BUILD_DIR = build
SRC_DIR = src

all: tdb_reader.a

tdb_reader.a: $(BUILD_DIR)/tdb_reader.o $(BUILD_DIR)/dpi_c_interface.o
	ar -r $@ $^

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cpp
	g++ -c -o build/$(notdir $@) $< -I/opt/synopsys/vcs2018/vcs/O-2018.09-SP2/include

clean:
	rm -f *.o *.a
	rm -f $(BUILD_DIR)/*.o $(BUILD_DIR)/*.a
