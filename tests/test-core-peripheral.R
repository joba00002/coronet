## This file is part of coronet, which is free software: you
## can redistribute it and/or modify it under the terms of the GNU General
## Public License as published by  the Free Software Foundation, version 2.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License along
## with this program; if not, write to the Free Software Foundation, Inc.,
## 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
##
## Copyright 2019 by Jakob Kronawitter <kronawij@fim.uni-passau.de>
## Copyright 2019 by Claus Hunsen <hunsen@fim.uni-passau.de>
## Copyright 2019 by Thomas Bock <bockthom@fim.uni-passau.de>
## Copyright 2019 by Christian Hechtl <hechtl@fim.uni-passau.de>
## Copyright 2021 by Christian Hechtl <hechtl@cs.uni-saarland.de>
## All Rights Reserved.


context("Tests for the file 'util-core-peripheral.R'")

##
## Context
##

CF.DATA = file.path(".", "codeface-data")
CF.SELECTION.PROCESS = "testing"
CASESTUDY = "test"
ARTIFACT = "feature"

## use only when debugging this file independently
if (!dir.exists(CF.DATA)) CF.DATA = file.path(".", "tests", "codeface-data")

## Prepare global setting
proj.conf = ProjectConf$new(CF.DATA, CF.SELECTION.PROCESS, CASESTUDY, ARTIFACT)
proj.conf$update.value("issues.only.comments", FALSE)
proj.data = ProjectData$new(proj.conf)

net.conf = NetworkConf$new()
net.builder = NetworkBuilder$new(proj.data, net.conf)

network = net.builder$get.author.network()

test_that("Vertex-degree classification using 'restrict.classification.to.authors'", {

    ## Act
    result = get.author.class.network.degree(network,
                                             restrict.classification.to.authors = c("Olaf", "Björn", "Darth Sidious"))

    ## Assert
    expected.core = data.frame(author.name = c("Olaf"), vertex.degree = c(4))
    expected.peripheral = data.frame(author.name = c("Björn", "Darth Sidious"), vertex.degree = c(2, NA))
    expected = list(core = expected.core, peripheral = expected.peripheral)

    row.names(result$core) = NULL
    row.names(result$peripheral) = NULL
    expect_equal(expected, result)
})

test_that("Eigenvector classification", {

    ## Act
    set.seed(0)
    result = get.author.class.network.eigen(network)

    ## Assert
    expected.core = data.frame(author.name = c("Olaf", "Thomas"),
                               eigen.centrality = c(1.0, 0.7116159)) # the threshold is 0.7116148
    expected.peripheral = data.frame(author.name = c("Björn", "udo", "Fritz fritz@example.org", "georg", "Hans"),
                                     eigen.centrality = c(0.7116104, 0.2499983, 0.2499983, 0.2499983, 0.2499983))
    expected = list(core = expected.core, peripheral = expected.peripheral)

    row.names(result$core) = NULL
    row.names(result$peripheral) = NULL
    expect_equal(expected, result, tolerance = 0.0001)
})

# TODO: Add a test for hierarchy classification

test_that("Commit-count classification using 'result.limit'" , {

    ## Act
    result = get.author.class.commit.count(proj.data, result.limit = 3)

    ## Assert
    expected.core = data.frame(author.name = c("Björn", "Olaf", "Thomas"), commit.count = c(1, 1, 1))
    expected = list(core = expected.core, peripheral = expected.core[0, ])

    row.names(result$core) = NULL
    row.names(result$peripheral) = NULL
    expect_equal(expected, result)
})

test_that("LOC-count classification" , {

    ## Act
    result = get.author.class.loc.count(proj.data)

    ## Assert
    expected.core = data.frame(author.name = c("Björn", "Olaf", "Thomas"), loc.count = c(2, 1, 1))
    expected = list(core = expected.core, peripheral = expected.core[0, ])

    row.names(result$core) = NULL
    row.names(result$peripheral) = NULL
    expect_equal(expected, result)
})

test_that("Mail-count classification" , {

    ## Act
    result = get.author.class.mail.count(proj.data)

    ## Assert
    expected.core = data.frame(author.name = c("Hans", "Björn", "Olaf", "Fritz fritz@example.org"),
                               mail.count = c(7, 3, 2, 1))
    expected.peripheral = data.frame(author.name = c("Thomas", "georg", "udo"), mail.count = c(1, 1, 1))
    expected = list(core = expected.core, peripheral = expected.peripheral)

    row.names(result$core) = NULL
    row.names(result$peripheral) = NULL
    expect_equal(expected, result)
})

test_that("Mail-thread-count classification" , {

    ## Act
    result = get.author.class.mail.thread.count(proj.data)

    ## Assert
    expected.core = data.frame(author.name = c("Björn", "Hans", "Olaf", "Fritz fritz@example.org", "Thomas"),
                               mail.thread.count = c(3, 2, 2, 1, 1))
    expected.peripheral = data.frame(author.name = c("georg", "udo"), mail.thread.count = c(1, 1))
    expected = list(core = expected.core, peripheral = expected.peripheral)

    row.names(result$core) = NULL
    row.names(result$peripheral) = NULL
    expect_equal(expected, result)
})

test_that("Issue-count classification" , {

    ## Act
    result = get.author.class.issue.count(proj.data, issue.type = "all")

    ## Assert
    expected.core = data.frame(author.name = c("Björn", "Olaf", "Thomas"), issue.count = c(6, 6, 4))
    expected.peripheral = data.frame(author.name = c("Karl", "Max", "udo"), issue.count = c(1, 1, 1))
    expected = list(core = expected.core, peripheral = expected.peripheral)

    row.names(result$core) = NULL
    row.names(result$peripheral) = NULL
    expect_equal(expected, result)
})

test_that("Issue-comment-count classification" , {

    ## Act
    result = get.author.class.issue.comment.count(proj.data, issue.type = "issues")

    ## Assert
    expected.core = data.frame(author.name = c("Björn", "Olaf", "Max"),
                               issue.comment.count = c(9, 4, 3))
    expected.peripheral = data.frame(author.name = c("Thomas", "Karl"),
                               issue.comment.count = c(2, 1))
    expected = list(core = expected.core, peripheral = expected.peripheral)

    row.names(result$core) = NULL
    row.names(result$peripheral) = NULL
    expect_equal(expected, result)
})

test_that("Issue-commented-in-count classification" , {

    ## Act
    result = get.author.class.issue.commented.in.count(proj.data)

    ## Assert
    expected.core = data.frame(author.name = c("Björn", "Olaf", "Thomas"),
                               issue.commented.in.count = c(5, 3, 3))
    expected.peripheral = data.frame(author.name = c("Karl", "Max"),
                                     issue.commented.in.count = c(1, 1))
    expected = list(core = expected.core, peripheral = expected.peripheral)

    row.names(result$core) = NULL
    row.names(result$peripheral) = NULL
    expect_equal(expected, result)
})

test_that("Issue-created-count classification" , {

    ## Act
    result = get.author.class.issue.created.count(proj.data, issue.type = "pull.requests")

    ## Assert
    expected.core = data.frame(author.name = c("Björn", "Olaf", "Thomas"),
                               issue.created.count = c(1, 1, 1))
    expected = list(core = expected.core, peripheral = expected.core[0, ])

    row.names(result$core) = NULL
    row.names(result$peripheral) = NULL
    expect_equal(expected, result)
})

test_that("get.author.class", {

    ## Check all same values:
    ## 1) Arrange
    prepared.authors = data.frame(author.name = c("AAA", "BBB", "CCC", "DDD", "EEE"), centrality = c(1, 1, 1, 1, 1))
    ## 2) Act
    result = get.author.class(prepared.authors, "centrality", classification.category = "count")
    ## 3) Assert
    expected = list(core = prepared.authors[1:4, ], peripheral = prepared.authors[5, ])
    expect_identical(result, expected)

    ## Check fractions and inherent rounding:
    ## 1) Arrange
    prepared.authors = data.frame(author.name = c("AAA", "BBB", "CCC"), centrality = c(0.5, 0.29, 0.21))
    ## 2) Act
    result = get.author.class(prepared.authors, "centrality", classification.category = "count")
    ## 3) Assert
    expected = list(core = prepared.authors, peripheral = prepared.authors[0, ])
    expect_identical(result, expected)

    ## Check all zero values:
    ## 1) Arrange
    prepared.authors = data.frame(author.name = c("AAA", "BBB", "CCC"), centrality = c(0, 0, 0))
    ## 2) Act
    result = get.author.class(prepared.authors, "centrality", classification.category = "count")
    ## 3) Assert
    expected = list(core = prepared.authors[0, ], peripheral = prepared.authors)
    expect_identical(result, expected)

    ## Check empty input data.frame:
    ## 1) Arrange
    prepared.authors = data.frame(author.name = character(0), centrality = numeric(0))
    ## 2) Act
    result = get.author.class(prepared.authors, "centrality", classification.category = "count")
    ## 3) Assert
    expected = list(core = prepared.authors, peripheral = prepared.authors)
    expect_identical(result, expected)

    ## Check empty input data for count-based classification (no columns):
    expect_error(get.author.class(data.frame(author.name = character(0), foo = numeric(0)), "foo",
                                  classification.category = "count"), NA) # expect that no error occurs
    ## Check empty input data for count-based classification (not enough columns) (1):
    expect_error(get.author.class(data.frame(), "foo",
                                  classification.category = "count"), NA) # expect that no error occurs
    ## Check empty input data for count-based classification (not enough columns) (2):
    expect_error(get.author.class(data.frame(author.name = character(0)), "foo",
                                  classification.category = "count"), NA) # expect that no error occurs

    ## Check empty input data for network-based classification (no columns):
    expect_error(get.author.class(data.frame(author.name = character(0), foo = numeric(0)), "foo",
                                  classification.category = "network"), NA) # expect that no error occurs
    ## Check empty input data for network-based classification (not enough columns) (1):
    expect_error(get.author.class(data.frame(), "foo",
                                  classification.category = "network"), NA) # expect that no error occurs
    ## Check empty input data for network-based classification (not enough columns) (2):
    expect_error(get.author.class(data.frame(author.name = character(0)), "foo",
                                  classification.category = "network"), NA) # expect that no error occurs

    ## Check empty input data without a specified classification metric type (not enough columns) (2):
    expect_error(get.author.class(data.frame(author.name = character(0)), "foo")) # expect that an error occurs

    ## Check empty input data with wrong classification metric type (not enough columns) (2):
    expect_error(get.author.class(data.frame(author.name = character(0)), "foo",
                                  classification.category = "Busted")) # expect that an error occurs

})

test_that("Core classification of cochange author networks with vertices but no edges", {
    ## create network with one author and no edges
    authors = data.frame(author.name = "A", kind = TYPE.AUTHOR, type = TYPE.AUTHOR)
    edges = create.empty.edge.list()
    network = igraph::graph.data.frame(edges, directed = TRUE, vertices = authors)

    ## classify the authors into core/peripheral
    classification = get.author.class.by.type(network, type = "network.eigen")

    expect_true(nrow(classification[["core"]]) == 0 && nrow(classification[["peripheral"]]) == 1)

    ## create network with several authors and no edges
    authors = data.frame(author.name = LETTERS[1:5], kind = TYPE.AUTHOR, type = TYPE.AUTHOR)
    edges = create.empty.edge.list()
    network = igraph::graph.data.frame(edges, directed = TRUE, vertices = authors)

    ## classify the authors into core/peripheral
    classification = get.author.class.by.type(network, type = "network.eigen")

    expect_true(nrow(classification[["core"]]) == 0 && nrow(classification[["peripheral"]]) == 5)
})
