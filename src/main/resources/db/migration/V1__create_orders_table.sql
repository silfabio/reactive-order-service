CREATE TABLE ORDERS (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_name VARCHAR(255) NOT NULL,
    amount INT NOT NULL,
    status VARCHAR(50)
);

CREATE INDEX idx_orders_status ON ORDERS(status);
CREATE INDEX idx_orders_item_name ON ORDERS(item_name);