#include <iostream>
#include <fstream>
#include <sstream>
#include <cstdint>
#include <array>
#include <map>

#include <unistd.h>
#include <stdlib.h>
#include <pwd.h>

#include <boost/algorithm/string.hpp>

constexpr std::size_t BUF_SIZE = 512;
constexpr std::size_t PW_LEN = 15;

using pw_key = std::string;
using pw_val = std::string;
using pw_container = std::map<pw_key, pw_val>;

static std::string get_user_name()
{
  uid_t uid = geteuid();
  struct passwd *pw = getpwuid(uid);
  if (pw)
  {
      return pw->pw_name;
    }

  return "";
}
static std::string get_path()
{
    std::ostringstream path;
    path << "/home/" << get_user_name() << "/.pwdb";
    return path.str();
}

static void load_pws(pw_container& pw_map)
{
    std::ifstream fs(get_path(), std::ios::in);
    char buf[BUF_SIZE];

    while(fs.getline( buf, BUF_SIZE))
    {
        std::string s(buf);
        std::vector<std::string> tokens;
        boost::split(tokens, s, boost::is_any_of(" "), boost::token_compress_on);
        if(tokens.size() == 2) {
            pw_map[tokens[0]] = tokens[1];
        } else {
            throw std::runtime_error("bad entry in password file");
        }
    }
}

static void write_key(pw_container& pws)
{
    std::ofstream of(get_path(), std::ios::out);
    for(auto e : pws) {
        of << e.first << " " << e.second << std::endl;
    }
    of.flush();
}

static pw_val gen_pass(const uint8_t pw_len = PW_LEN)
{
    std::ifstream fs("/dev/random", std::ios::in);

    std::ostringstream out;
    uint8_t count = 0;

    while(count < pw_len)
    {
        char c;
        fs.read(&c, sizeof(c));
        if(c > 0x20 && c < 0x7A && c!='"' && c!= '\'') 
        {
            out << (char)c;    
            count++;
        }
    }

    const pw_val pw = out.str();

    return pw;
}

int main(const int argc, const char **argv)
{
    bool gen = false;
    bool get = false;
    pw_key key;
    std::size_t pw_len = PW_LEN;

    pw_container pws;
    load_pws(pws);

    try {
        for(int i=0; i<argc; i++)
        {
            std::string arg(argv[i]);
            if(arg == "--gen" && !get) {
                gen = true;
                i++;
                if(i>=argc) throw std::runtime_error("--gen expects an argument");
                key = argv[i];
            } else if(arg == "--key" && !gen) {
                get = true;
                i++;
                if(i>=argc) throw std::runtime_error("--key expects an argument");
                key = argv[i];
            } else if(arg == "--len") {
                pw_len = std::atoi(argv[++i]);
            } else {
                // bleh
            }
        }

        if(get) {
            std::cout << pws.at(key);
        } else if(gen) {
            const pw_val pw = gen_pass(pw_len);
            pws[key] = pw;
            write_key(pws);
            std::cout << pw << std::endl;
        } else {
            throw std::runtime_error("wtf dude?!?!");
        }
    } catch(const std::out_of_range& e) {
        std::cerr << "ERROR: '" << key << "' not found" << std::endl;
    } catch(const std::exception& e) {
        std::cerr << "ERROR: " << e.what() << std::endl;
        return 1;
    }
    return 0;
}

