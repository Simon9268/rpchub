#ifndef __HUB_DB_HELPER_H_
#define __HUB_DB_HELPER_H_

#include <cstdint>
#include <optional>
#include <string>
#include <vector>

#include <sqlpp11/functions.h>
#include <sqlpp11/schema.h>
#include <sqlpp11/select.h>
#include <sqlpp11/transaction.h>

#include "db.h"
#include "schema/schema.h"

namespace hub {
namespace db {

inline std::optional<int64_t> userIdFromIdentifier(
    Connection& connection, const std::string& identifier) {
  using namespace sqlpp;

  db::sql::UserAccount acc;

  const auto result =
      connection(select(acc.id).from(acc).where(acc.identifier == identifier));

  if (result.empty()) {
    return {};
  } else {
    return result.front().id;
  }
}

using AddressWithID = std::tuple<uint64_t, std::string>;

inline std::vector<AddressWithID> unsweptUserAddresses(Connection& connection) {
  using namespace sqlpp;

  db::sql::UserAddress addr;
  db::sql::UserAddressBalance bal;

  std::vector<AddressWithID> addresses;

  auto result =
      connection(select(addr.id, addr.address)
                     .from(addr)
                     .where(not(exists(select(bal.id).from(bal).where(
                         bal.userAddress == addr.id and bal.reason == 1)))));

  for (const auto& row : result) {
    addresses.push_back({row.id, row.address});
  }

  return addresses;
}

}  // namespace db
}  // namespace hub

#endif /* __HUB_DB_HELPER_H_ */
