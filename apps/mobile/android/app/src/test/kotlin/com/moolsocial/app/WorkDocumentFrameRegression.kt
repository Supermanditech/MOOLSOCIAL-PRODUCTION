package com.moolsocial.app

import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.DataOutputStream
import java.io.IOException
import java.io.InputStream

/**
 * Dependency-free JVM tests of the actual production frame implementation.
 * Run this main with the compiled native owners; exact command is in r66.9 local-validation.md.
 * These tests do not qualify Android Binder, PdfRenderer or device security.
 */
object WorkDocumentFrameRegression {
    @JvmStatic
    fun main(args: Array<String>) {
        var passed = 0
        fun test(name: String, action: () -> Unit) {
            action()
            passed++
            println("PASS: $name")
        }
        fun rejected(action: () -> Unit) {
            val failure = runCatching(action).exceptionOrNull()
            check(failure is IllegalArgumentException || failure is IllegalStateException ||
                failure is IOException) { "Expected bounded rejection; got $failure" }
        }
        fun packet(bytes: ByteArray): ByteArray = ByteArrayOutputStream().also {
            WorkDocumentPageFrame.write(it, bytes)
        }.toByteArray()
        fun declared(length: Int, body: ByteArray = byteArrayOf()): ByteArray =
            ByteArrayOutputStream().also {
                DataOutputStream(it).apply { writeInt(length); write(body) }
            }.toByteArray()
        fun heldOpen(bytes: ByteArray): InputStream = object : InputStream() {
            private val input = ByteArrayInputStream(bytes)
            override fun read(): Int {
                if (input.available() == 0) throw IOException("Writer remains open; EOF unavailable")
                return input.read()
            }
            override fun read(target: ByteArray, offset: Int, length: Int): Int {
                if (input.available() == 0) throw IOException("Writer remains open; EOF unavailable")
                return input.read(target, offset, minOf(length, 7))
            }
        }
        val page = ByteArray(91_317) { (it % 251).toByte() }
        test("round trip preserves every payload byte") {
            check(WorkDocumentPageFrame.read(ByteArrayInputStream(packet(page))).contentEquals(page))
        }
        test("exact frame completes with fragmented reads and writer still open") {
            check(WorkDocumentPageFrame.read(heldOpen(packet(page))).contentEquals(page))
        }
        test("legacy EOF algorithm cannot complete the retained-writer model") {
            // Same terminating condition as the preserved r66.8 reader; diagnostic model only.
            rejected {
                heldOpen(page).use { input ->
                    val buffer = ByteArray(32 * 1024)
                    while (input.read(buffer) >= 0) { /* awaits EOF */ }
                }
            }
        }
        test("minimum payload length accepted") {
            val bytes = ByteArray(24)
            check(WorkDocumentPageFrame.read(ByteArrayInputStream(packet(bytes))).size == 24)
        }
        test("maximum payload length accepted") {
            val bytes = ByteArray(WorkDocumentPageFrame.MAX_BYTES)
            check(WorkDocumentPageFrame.read(ByteArrayInputStream(packet(bytes))).contentEquals(bytes))
        }
        for (length in listOf(Int.MIN_VALUE, -1, 0, 1, 23, WorkDocumentPageFrame.MAX_BYTES + 1, Int.MAX_VALUE)) {
            test("invalid declared length $length rejected before payload allocation") {
                rejected { WorkDocumentPageFrame.read(ByteArrayInputStream(declared(length))) }
            }
        }
        test("truncated length header rejected") {
            rejected { WorkDocumentPageFrame.read(ByteArrayInputStream(byteArrayOf(0, 0, 1))) }
        }
        test("truncated payload rejected") {
            rejected { WorkDocumentPageFrame.read(ByteArrayInputStream(declared(100, ByteArray(99)))) }
        }
        test("zero-progress payload does not loop") {
            val input = object : InputStream() {
                private val header = ByteArrayInputStream(declared(24))
                override fun read(): Int = header.read()
                override fun read(target: ByteArray, offset: Int, length: Int): Int = 0
            }
            rejected { WorkDocumentPageFrame.read(input) }
        }
        test("cancelled or failed payload read rejected") {
            rejected { WorkDocumentPageFrame.read(heldOpen(declared(24, ByteArray(3)))) }
        }
        test("producer encoding preserves bytes") {
            check(WorkDocumentPageFrame.encode { it.write(page) }.contentEquals(page))
        }
        test("producer chunk cap enforced before growth") {
            rejected {
                WorkDocumentPageFrame.encode {
                    it.write(ByteArray(WorkDocumentPageFrame.MAX_BYTES))
                    it.write(byteArrayOf(1))
                }
            }
        }
        test("producer single-byte cap enforced") {
            rejected {
                WorkDocumentPageFrame.encode {
                    it.write(ByteArray(WorkDocumentPageFrame.MAX_BYTES))
                    it.write(1)
                }
            }
        }
        test("empty producer output rejected") {
            rejected { WorkDocumentPageFrame.encode { } }
        }
        test("oversized outgoing payload rejected") {
            rejected { packet(ByteArray(WorkDocumentPageFrame.MAX_BYTES + 1)) }
        }
        test("undersized outgoing payload rejected") {
            rejected { packet(ByteArray(23)) }
        }
        test("outgoing stream failure propagated") {
            rejected {
                WorkDocumentPageFrame.write(object : java.io.OutputStream() {
                    override fun write(value: Int) { throw IOException("Cancelled output") }
                }, page)
            }
        }
        println("TOTAL: $passed passed; 0 failed; 0 skipped")
    }
}
