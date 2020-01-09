/** test-header.hpp
 * Short description here.
 *
 * Copyright © 2020 Gene Harvey
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#ifndef CREATE_PACKAGE_TEST_HEADER_HPP
#define CREATE_PACKAGE_TEST_HEADER_HPP

#include <iostream>

class test_class
{
public:
  static void print (void)
  {
    std::cout << "Hello, world." << std::endl;
  }
};

#endif /* CREATE_PACKAGE_TEST_HEADER_HPP */
