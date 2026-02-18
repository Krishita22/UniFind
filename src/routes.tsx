import { createBrowserRouter } from "react-router";
import { Root } from "./components/Root";
import { Home } from "./components/Home";
import { LostAndFound } from "./components/LostAndFound";
import { PostItem } from "./components/PostItem";
import { ItemDetail } from "./components/ItemDetail";
import { MyListings } from "./components/MyListings";
import { Documentation } from "./components/Documentation";
import { NotFound } from "./components/NotFound";

export const router = createBrowserRouter([
  {
    path: "/",
    Component: Root,
    children: [
      { index: true, Component: Home },
      { path: "lost-found", Component: LostAndFound },
      { path: "post", Component: PostItem },
      { path: "item/:id", Component: ItemDetail },
      { path: "my-listings", Component: MyListings },
      { path: "docs", Component: Documentation },
      { path: "*", Component: NotFound },
    ],
  },
]);