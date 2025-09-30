
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

.PHONY: recon investigate hound report mindpalace

recon:
	$(BUILD_DIR)/$(TARGET) recon $(ARGS)

investigate:
	$(BUILD_DIR)/$(TARGET) investigate $(ARGS)

hound:
	$(BUILD_DIR)/$(TARGET) hound $(ARGS)

report:
	$(BUILD_DIR)/$(TARGET) report $(ARGS)

mindpalace:
	$(BUILD_DIR)/$(TARGET) mindpalace $(ARGS)

.PHONY: doctor
doctor:
	$(BUILD_DIR)/$(TARGET) doctor

clean:
	cargo clean

test:
	cargo test
