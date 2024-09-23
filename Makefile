
# Makefile for Sherlock Rust project

TARGET = sherlock
BUILD_DIR = target/release

.PHONY: all build install run clean test

all: build

build:
	cargo build --release

install:
	cargo install --path .

run:
	$(BUILD_DIR)/$(TARGET)

clean:
	cargo clean

test:
	cargo test
